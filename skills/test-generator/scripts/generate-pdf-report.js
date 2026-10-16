#!/usr/bin/env node

/**
 * Generate PDF report from markdown test summary.
 * 
 * This script provides a deterministic way to convert markdown test summaries
 * to PDF format with proper styling and formatting using markdown-pdf.
 * 
 * Usage:
 *   node generate-pdf-report.js <markdown_file> [output_pdf]
 * 
 * Requirements:
 *   - Node.js v24 (already required by APIM CLI)
 *   - markdown-pdf package (auto-installed if missing)
 */

const fs = require('fs');
const path = require('path');
const { execSync, spawn } = require('child_process');

/**
 * Check if markdown-pdf is installed
 */
function checkMarkdownPdf() {
    try {
        require.resolve('markdown-pdf');
        return true;
    } catch (e) {
        return false;
    }
}

/**
 * Install markdown-pdf package
 */
function installMarkdownPdf() {
    console.log('Installing markdown-pdf package...');
    try {
        execSync('npm install -g markdown-pdf', { stdio: 'inherit' });
        console.log('✓ markdown-pdf installed successfully');
        return true;
    } catch (error) {
        console.error('Error installing markdown-pdf:', error.message);
        console.error('\nPlease install manually:');
        console.error('  npm install -g markdown-pdf');
        return false;
    }
}

/**
 * Generate PDF from markdown file
 */
function generatePdf(markdownFile, outputPdf) {
    return new Promise((resolve, reject) => {
        // Validate input file
        if (!fs.existsSync(markdownFile)) {
            reject(new Error(`Markdown file not found: ${markdownFile}`));
            return;
        }

        // Determine output path
        const outputPath = outputPdf || markdownFile.replace(/\.md$/, '.pdf');

        console.log(`Generating PDF: ${outputPath}`);
        console.log(`From markdown: ${markdownFile}`);

        // Use markdown-pdf command
        const mdpdf = spawn('markdown-pdf', [
            markdownFile,
            '-o', outputPath,
            '--remarkable-options', JSON.stringify({
                html: true,
                breaks: true,
                typographer: true
            }),
            '--css-path', path.join(__dirname, 'pdf-styles.css')
        ]);

        let stderr = '';

        mdpdf.stderr.on('data', (data) => {
            stderr += data.toString();
        });

        mdpdf.on('close', (code) => {
            if (code === 0) {
                if (fs.existsSync(outputPath)) {
                    const stats = fs.statSync(outputPath);
                    console.log(`✓ PDF generated successfully: ${outputPath}`);
                    console.log(`  File size: ${(stats.size / 1024).toFixed(1)} KB`);
                    resolve(outputPath);
                } else {
                    reject(new Error('PDF file was not created'));
                }
            } else {
                reject(new Error(`PDF generation failed with code ${code}\n${stderr}`));
            }
        });

        mdpdf.on('error', (error) => {
            reject(new Error(`Failed to start markdown-pdf: ${error.message}`));
        });
    });
}

/**
 * Create default CSS file for PDF styling
 */
function createDefaultCss() {
    const cssPath = path.join(__dirname, 'pdf-styles.css');

    if (fs.existsSync(cssPath)) {
        return; // CSS file already exists
    }

    const css = `
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
  font-size: 11pt;
  line-height: 1.6;
  color: #333;
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
}

h1 {
  color: #0f62fe;
  border-bottom: 2px solid #0f62fe;
  padding-bottom: 10px;
  margin-top: 30px;
}

h2 {
  color: #0f62fe;
  border-bottom: 1px solid #e0e0e0;
  padding-bottom: 5px;
  margin-top: 25px;
}

h3 {
  color: #161616;
  margin-top: 20px;
}

table {
  border-collapse: collapse;
  width: 100%;
  margin: 15px 0;
}

th, td {
  border: 1px solid #e0e0e0;
  padding: 8px 12px;
  text-align: left;
}

th {
  background-color: #f4f4f4;
  font-weight: 600;
}

tr:nth-child(even) {
  background-color: #fafafa;
}

code {
  background-color: #f4f4f4;
  padding: 2px 6px;
  border-radius: 3px;
  font-family: 'Monaco', 'Menlo', 'Courier New', monospace;
  font-size: 0.9em;
}

pre {
  background-color: #f4f4f4;
  padding: 15px;
  border-radius: 5px;
  overflow-x: auto;
}

pre code {
  background-color: transparent;
  padding: 0;
}

ul, ol {
  margin: 10px 0;
  padding-left: 30px;
}

li {
  margin: 5px 0;
}

strong {
  font-weight: 600;
  color: #161616;
}

a {
  color: #0f62fe;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}

.passed {
  color: #24a148;
}

.failed {
  color: #da1e28;
}
`;

    fs.writeFileSync(cssPath, css.trim());
    console.log(`Created default CSS file: ${cssPath}`);
}

/**
 * Main function
 */
async function main() {
    const args = process.argv.slice(2);

    if (args.length === 0) {
        console.log('Usage: node generate-pdf-report.js <markdown_file> [output_pdf]');
        console.log('\nExample:');
        console.log('  node generate-pdf-report.js test-report-20240623.md');
        console.log('  node generate-pdf-report.js test-report-20240623.md report.pdf');
        process.exit(1);
    }

    const markdownFile = args[0];
    const outputPdf = args[1];

    // Check if markdown-pdf is installed
    if (!checkMarkdownPdf()) {
        console.log('markdown-pdf is not installed.');
        const install = await installMarkdownPdf();
        if (!install) {
            process.exit(1);
        }
    }

    // Create default CSS if it doesn't exist
    createDefaultCss();

    // Generate PDF
    try {
        await generatePdf(markdownFile, outputPdf);
        process.exit(0);
    } catch (error) {
        console.error('Error:', error.message);
        process.exit(1);
    }
}

// Run main function
main().catch(error => {
    console.error('Unexpected error:', error);
    process.exit(1);
});

// Made with Bob
