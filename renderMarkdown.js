// renderMarkdown.js

// Function to fetch Markdown content and render it
function renderMarkdown(markdownFilePath) {
    // Fetch Markdown content
    fetch(markdownFilePath)
        .then(response => response.text())
        .then(markdownContent => {
            // Convert Markdown to HTML
            var converter = new showdown.Converter();
            var htmlContent = converter.makeHtml(markdownContent);

            // Display HTML content
            document.getElementById('markdownContent').innerHTML = htmlContent;
        })
        .catch(error => console.error('Error fetching Markdown:', error));
}

// Get the path to the Markdown file from the script tag's data attribute
var markdownPath = document.currentScript.getAttribute('data-markdown-path');

// Call renderMarkdown function with the Markdown file path
renderMarkdown(markdownPath);
