document.addEventListener('DOMContentLoaded', () => {
    const brandContainer = document.querySelector('.navbar-brand-container.mx-auto');
    if (brandContainer) {
        brandContainer.classList.add('dropdown');

        const brandLink = brandContainer.querySelector('a.navbar-brand');
        if (brandLink) {
            brandLink.classList.add('dropdown-toggle');
            brandLink.setAttribute('data-bs-toggle', 'dropdown');
            brandLink.setAttribute('aria-expanded', 'false');
        }

        const dropdownMenu = document.createElement('ul');
        dropdownMenu.classList.add('dropdown-menu');

        titleDropdownMenuItems.forEach(item => {
            const li = document.createElement('li');
            const a = document.createElement('a');
            a.classList.add('dropdown-item');
            a.href = item.href;
            a.textContent = item.text;
            li.appendChild(a);
            dropdownMenu.appendChild(li);
        });

        brandContainer.appendChild(dropdownMenu);
    }
});
