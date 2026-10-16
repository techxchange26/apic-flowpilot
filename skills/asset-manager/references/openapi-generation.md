# OpenAPI Specification Generation from Workspace Analysis

This reference provides detailed guidance for generating OpenAPI 3.0 specifications by analyzing workspace code when no OpenAPI spec is provided.

## Overview

When a user wants to create an API but doesn't have an OpenAPI specification, analyze the workspace to discover:
- Service endpoints and routes
- HTTP methods and paths
- Request/response data models
- Authentication mechanisms
- Backend service URLs

## Analysis Steps

### 1. Identify Project Type

Determine the programming language and framework:

```bash
# Check for package files
ls package.json 2>/dev/null && echo "Node.js project"
ls requirements.txt 2>/dev/null && echo "Python project"
ls pom.xml 2>/dev/null && echo "Java/Maven project"
ls build.gradle 2>/dev/null && echo "Java/Gradle project"
ls go.mod 2>/dev/null && echo "Go project"
```

### 2. Find Service Definitions

#### Node.js/Express

```bash
# Find route files
find . -type f \( -name "*routes*.js" -o -name "*routes*.ts" -o -name "app.js" -o -name "server.js" \) 2>/dev/null

# Find controllers
find . -type f \( -name "*controller*.js" -o -name "*controller*.ts" \) 2>/dev/null
```

**Common patterns:**
```javascript
// Express routes
app.get('/api/weather/:city', (req, res) => { ... });
router.post('/api/forecast', forecastController.create);

// Route definitions
const routes = {
  '/weather': weatherController,
  '/forecast': forecastController
};
```

#### Python/Flask/FastAPI

```bash
# Find route files
find . -type f \( -name "routes.py" -o -name "views.py" -o -name "*api*.py" -o -name "main.py" \) 2>/dev/null

# Find models
find . -type f \( -name "models.py" -o -name "schemas.py" \) 2>/dev/null
```

**Common patterns:**
```python
# Flask
@app.route('/api/weather/<city>', methods=['GET'])
def get_weather(city):
    ...

# FastAPI
@router.get("/api/weather/{city}")
async def get_weather(city: str):
    ...

# Pydantic models
class WeatherResponse(BaseModel):
    temperature: float
    humidity: int
```

#### Java/Spring Boot

```bash
# Find controllers
find . -type f -name "*Controller.java" 2>/dev/null

# Find entities/DTOs
find . -type f \( -name "*Entity.java" -o -name "*DTO.java" \) 2>/dev/null
```

**Common patterns:**
```java
@RestController
@RequestMapping("/api/weather")
public class WeatherController {
    
    @GetMapping("/{city}")
    public ResponseEntity<WeatherResponse> getWeather(@PathVariable String city) {
        ...
    }
    
    @PostMapping("/forecast")
    public ResponseEntity<ForecastResponse> createForecast(@RequestBody ForecastRequest request) {
        ...
    }
}
```

#### Go

```bash
# Find handler files
find . -type f \( -name "*handler*.go" -o -name "*routes*.go" \) 2>/dev/null
```

**Common patterns:**
```go
// Gorilla mux
r.HandleFunc("/api/weather/{city}", getWeather).Methods("GET")

// Gin
router.GET("/api/weather/:city", getWeather)
router.POST("/api/forecast", createForecast)
```

### 3. Extract Endpoint Information

For each discovered endpoint, extract:

**Path:** `/api/weather/{city}`
**Method:** `GET`, `POST`, `PUT`, `DELETE`, etc.
**Parameters:**
- Path parameters: `{city}`
- Query parameters: `?units=metric`
- Headers: `Authorization`, `Content-Type`

**Request body:** (for POST/PUT)
- Content type: `application/json`
- Schema: Data model structure

**Response:**
- Status codes: `200`, `404`, `500`
- Content type: `application/json`
- Schema: Response data structure

### 4. Discover Data Models

#### From Code

**TypeScript/JavaScript:**
```typescript
interface WeatherResponse {
  temperature: number;
  humidity: number;
  conditions: string;
  city: string;
}
```

**Python (Pydantic):**
```python
class WeatherResponse(BaseModel):
    temperature: float
    humidity: int
    conditions: str
    city: str
```

**Java:**
```java
public class WeatherResponse {
    private Double temperature;
    private Integer humidity;
    private String conditions;
    private String city;
}
```

#### From Database Models

If database models exist, they often map to API responses:

```python
# SQLAlchemy
class Weather(Base):
    __tablename__ = 'weather'
    id = Column(Integer, primary_key=True)
    city = Column(String)
    temperature = Column(Float)
    humidity = Column(Integer)
```

### 5. Identify Security Mechanisms

Look for authentication/authorization patterns:

**JWT Tokens:**
```javascript
// Middleware checking Authorization header
const token = req.headers.authorization?.split(' ')[1];
jwt.verify(token, secret);
```

**API Keys:**
```python
# Header or query parameter
api_key = request.headers.get('X-API-Key')
```

**OAuth2:**
```java
@PreAuthorize("hasAuthority('SCOPE_read')")
```

### 6. Detect Backend Services

Find backend service URLs:

```javascript
// Environment variables
const BACKEND_URL = process.env.WEATHER_API_URL || 'https://api.weather.example.com';

// Configuration files
const config = {
  weatherService: 'https://api.weather.example.com',
  timeout: 5000
};
```

## Generating OpenAPI Specification

### OpenAPI 3.0 Structure

```yaml
openapi: 3.0.0
info:
  title: <API Title>
  version: <version>
  description: <description>
servers:
  - url: <backend-url>
    description: <environment>
paths:
  <path>:
    <method>:
      summary: <summary>
      parameters: [...]
      requestBody: {...}
      responses: {...}
      security: [...]
components:
  schemas: {...}
  securitySchemes: {...}
```

### Example: Complete OpenAPI Generation

**From this Express code:**
```javascript
// routes/weather.js
router.get('/api/weather/:city', async (req, res) => {
  const { city } = req.params;
  const { units } = req.query;
  const weather = await weatherService.getWeather(city, units);
  res.json(weather);
});

router.post('/api/forecast', async (req, res) => {
  const { city, days } = req.body;
  const forecast = await weatherService.getForecast(city, days);
  res.json(forecast);
});

// middleware/auth.js
const verifyToken = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  jwt.verify(token, process.env.JWT_SECRET);
  next();
};
```

**Generate this OpenAPI spec:**
```yaml
openapi: 3.0.0
info:
  title: Weather API
  version: 1.0.0
  description: Provides weather forecasts and current conditions
servers:
  - url: https://api.weather.example.com
    description: Production server
paths:
  /api/weather/{city}:
    get:
      summary: Get current weather for a city
      parameters:
        - name: city
          in: path
          required: true
          schema:
            type: string
          description: City name
        - name: units
          in: query
          required: false
          schema:
            type: string
            enum: [metric, imperial]
          description: Temperature units
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/WeatherResponse'
        '404':
          description: City not found
      security:
        - bearerAuth: []
  /api/forecast:
    post:
      summary: Get weather forecast
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ForecastRequest'
      responses:
        '200':
          description: Successful response
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ForecastResponse'
      security:
        - bearerAuth: []
components:
  schemas:
    WeatherResponse:
      type: object
      properties:
        temperature:
          type: number
        humidity:
          type: integer
        conditions:
          type: string
        city:
          type: string
    ForecastRequest:
      type: object
      required:
        - city
        - days
      properties:
        city:
          type: string
        days:
          type: integer
          minimum: 1
          maximum: 7
    ForecastResponse:
      type: object
      properties:
        city:
          type: string
        forecast:
          type: array
          items:
            $ref: '#/components/schemas/DailyForecast'
    DailyForecast:
      type: object
      properties:
        date:
          type: string
          format: date
        temperature:
          type: number
        conditions:
          type: string
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
```

## Best Practices

### 1. Start with Info Section

Always include:
- Clear title
- Semantic version (1.0.0)
- Meaningful description

### 2. Define Servers

Include at least one server URL:
```yaml
servers:
  - url: https://api.example.com
    description: Production
  - url: https://staging-api.example.com
    description: Staging
```

### 3. Document All Parameters

For each parameter, specify:
- Name and location (path, query, header)
- Required or optional
- Data type and format
- Description
- Constraints (enum, min, max, pattern)

### 4. Use Schema References

Define reusable schemas in `components/schemas` and reference them:
```yaml
$ref: '#/components/schemas/WeatherResponse'
```

### 5. Include Security Schemes

Document authentication:
```yaml
components:
  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
    apiKey:
      type: apiKey
      in: header
      name: X-API-Key
```

### 6. Add Response Examples

Include example responses:
```yaml
responses:
  '200':
    description: Success
    content:
      application/json:
        schema:
          $ref: '#/components/schemas/WeatherResponse'
        example:
          temperature: 22.5
          humidity: 65
          conditions: "Partly cloudy"
          city: "San Francisco"
```

### 7. Document Error Responses

Include common error codes:
```yaml
responses:
  '400':
    description: Bad request
  '401':
    description: Unauthorized
  '404':
    description: Not found
  '500':
    description: Internal server error
```

## Validation

After generating the OpenAPI spec, validate it:

```bash
# Using Swagger CLI (if available)
swagger-cli validate openapi.yaml

# Using online validator
# Upload to https://editor.swagger.io/
```

## Summary

When generating OpenAPI specs from workspace analysis:

1. Identify the project type and framework
2. Find route/controller files
3. Extract endpoints, methods, and parameters
4. Discover data models from code or database schemas
5. Identify authentication mechanisms
6. Detect backend service URLs
7. Generate complete OpenAPI 3.0 specification
8. Validate the generated spec

This ensures accurate API documentation that can be used to create IBM API Connect / APIC assets.