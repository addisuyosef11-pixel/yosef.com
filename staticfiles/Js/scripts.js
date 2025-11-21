document.addEventListener('DOMContentLoaded', function () {
  // ----- Animate Progress Bar (e.g., Profile Completion) -----
  const progressBar = document.querySelector('.progress-bar');
  if (progressBar) {
    const value = parseInt(progressBar.getAttribute('aria-valuenow')) || 0;
    progressBar.style.width = '0%';
    progressBar.textContent = '0%';

    let current = 0;
    const interval = setInterval(() => {
      if (current >= value) {
        clearInterval(interval);
      } else {
        current++;
        progressBar.style.width = current + '%';
        progressBar.textContent = current + '%';
      }
    }, 15); // Speed of animation
  }

  // ----- Prevent Copying Phone Number -----
  const phone = document.querySelector('.secure-phone');
  if (phone) {
    phone.addEventListener('copy', function (e) {
      e.preventDefault();
      alert('Copying phone number is not allowed.');
    });
  }

  // ----- Optional: Handle Form Spinner (if a form exists) -----
  const form = document.getElementById('contact-form');
  const btn = document.getElementById('submit-btn');
  const spinner = document.getElementById('spinner');
  const text = document.getElementById('submit-text');

  if (form && btn && spinner && text) {
    form.addEventListener('submit', function (e) {
      e.preventDefault(); // Prevent actual submit for demo purposes
      btn.disabled = true;
      spinner.classList.remove('d-none');
      text.textContent = 'Sending...';

      setTimeout(() => {
        text.textContent = 'Send';
        spinner.classList.add('d-none');
        btn.disabled = false;
        alert('Form submitted (simulated)');
        form.reset();
      }, 2000);
    });
  }
});



