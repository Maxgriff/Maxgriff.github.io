// Function to toggle dark mode
function toggleDarkMode() {
    // Toggle dark mode class on body
    document.body.classList.toggle('dark-mode');
    
    // Update button text based on current mode
    var isDarkMode = document.body.classList.contains('dark-mode');
    var buttonText = isDarkMode ? 'Light Mode' : 'Dark Mode';
    toggleModeButton.textContent = buttonText;
    
    // Store user's preferred mode in localStorage
    localStorage.setItem('preferredMode', isDarkMode ? 'dark' : 'light');
}

// Get the toggle button element
var toggleModeButton = document.getElementById('toggleModeButton');

// Attach click event listener to toggle button
toggleModeButton.addEventListener('click', toggleDarkMode);

// Check user's preferred mode from localStorage and set it
var preferredMode = localStorage.getItem('preferredMode');
if (preferredMode === 'dark') {
    toggleDarkMode(); // Toggle to dark mode if preferred mode is dark
}
