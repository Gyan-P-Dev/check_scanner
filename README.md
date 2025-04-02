# Check Scanner Application

- Table of Contents

- Introduction

- Features

- Installation

- Configuration

- Usage

- Troubleshooting

## Introduction

Check Scanner is a Ruby on Rails application designed to capture check images, extract data using OCR, and link them to invoices. This tool allows users to upload check images, verify company details, and ensure accurate invoicing.

## Features

Upload check images

Extract company details via OCR

Auto-select or create companies based on extracted data

Associate checks with invoices

Responsive UI with zoomable check images

Tab navigation for seamless user experience

## Installation

### Prerequisites

Ensure the following are installed on your system:

Ruby (2.7.7 or later)

Rails (7.1.5.1 or later)

MariaDB/MySQL

ImageMagick (for image processing)

If ImageMagick is not installed, install it using:

```
brew install imagemagick   # macOS
sudo apt install imagemagick   # Ubuntu/Debian
choco install imagemagick   # Windows (using Chocolatey)
```

### Setup Instructions

Clone the repository:

```
git clone https://github.com/Gyan-P-Dev/check_scanner

cd check-scanner
```

### Install dependencies:

```
bundle install
```

Set up database:

```
rails db:create
rails db:migrate
```

Start the Rails server:

`rails server`

The application will be available at `http://localhost:3000/`

### Configuration

#### ActiveStorage

Ensure ActiveStorage is set up correctly in `config/storage.yml`:

```test:
service: Disk
root: <%= Rails.root.join("tmp/storage") %>

local:
service: Disk
root: <%= Rails.root.join("storage") %>
```

To enable OCR, integrate an OCR tool like tesseract-ocr:

`brew install tesseract`

#### Usage

Upload a check image from the dashboard.

Verify extracted company details.

Associate the check with an invoice or create a new invoice.

View and manage checks through the admin panel.

#### Troubleshooting

Common Issues & Fixes

1. Address already in use - Port 3000

Solution: Stop any existing Rails server instance:

`kill -9 $(lsof -t -i:3000)`

2. ActiveStorage::FileNotFoundError

Solution: Run the following command to clean up missing files:

`rails active_storage:purge_unattached`

3. Images Not Displaying

Solution: Ensure you have run:

```rails active_storage:install
rails db:migrate
```

Contact & Support

📧 Email: gyandev081@gmail.com

🐙 GitHub: https://github.com/Gyan-P-Dev
