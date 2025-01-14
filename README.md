# Nginx LEMP Stack Installer

This repository contains a Bash script (`install_web_stack.sh`) that automates the installation and configuration of a LEMP (Linux, Nginx, MySQL, PHP) stack on Ubuntu. The script simplifies the process of setting up a web server environment specifically using Nginx, making it ideal for PHP applications.

## Features

- Installs Nginx as the web server.
- Installs MySQL Server for database management.
- Installs PHP-FPM for processing PHP scripts.
- Installs the PHP MySQL extension for database connectivity.
- Secures MySQL installation with a predefined root password.
- Creates a directory for your domain and sets appropriate permissions.
- Configures Nginx to serve your PHP applications.

## Prerequisites

- Ubuntu (preferably the latest LTS version).
- A user with sudo privileges.

## Usage

1. Clone this repository:

   ```bash
   git clone https://github.com/yourusername/nginx-lemp-stack-installer.git
   cd nginx-lemp-stack-installer
   ```

2. Make the script executable:

   ```bash
   chmod +x install_web_stack.sh
   ```

3. Edit the script to set your MySQL root password and domain:

  ```bash
  nano install_web_stack.sh
  ```

- Update the MYSQL_ROOT_PASSWORD variable with your desired password.
- Update the YOUR_DOMAIN variable with your domain name.

4. Run the script:

  ```
  ./install_web_stack.sh
  ```

5. After the script completes, you can access your web server at http://your_domain.com.

## Important Notes

- Ensure that your domain's DNS is properly configured to point to your server's IP address.
- The script assumes a fresh installation of Ubuntu. Running it on an existing server may lead to conflicts.
- Modify the script as needed to fit your specific requirements.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.
