# Job Application Tracker

A simple job application tracking system built with Python, FastAPI, PostgreSQL, and Docker. 
It allows users to track their job applications, including company details, role, application status, and associated notes.

## Features

*   List all tracked job applications on a landing page.
*   View detailed information for each job application.
*   Add new job applications with fields for Company Name (required), Role (required), Application Date, Status, Contact Person, Phone, URL, Cover Letter Sent, Interview Date, Offer Received, Salary, Equity, Bonus, Health Coverage, and PTO.
*   Edit existing job applications through a dedicated form.
*   Add timestamped notes to each job application.
*   Notes are displayed in descending order of creation (newest first).
*   Server-side rendered pages using Jinja2 templates and styled with Tailwind CSS.
*   Uses Docker Compose for easy setup and deployment with a PostgreSQL database.

## Prerequisites

*   Docker
*   Docker Compose (v2+ CLI - i.e., `docker compose` command)

## Setup and Running

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd application-tracker
    ```

2.  **Build and run the application using Docker Compose:**
    ```bash
    docker compose up --build
    ```
    The `web` service includes a wait script to ensure the database is ready before starting the application.

3.  The application will be accessible at [http://localhost:8000](http://localhost:8000).

## Project Structure

```
application-tracker/
├── app/                  # Main application code
│   ├── __init__.py
│   ├── main.py           # FastAPI application entry point
│   ├── models.py         # SQLAlchemy database models
│   ├── crud.py           # CRUD operations for database
│   ├── schemas.py        # Pydantic schemas for data validation
│   ├── database.py       # Database connection and session setup
│   ├── wait_for_db.py    # Script to ensure DB is ready before app start
│   ├── routers/          # API routers (currently unused, routes in main.py)
│   │   ├── __init__.py
│   └── templates/        # Jinja2 HTML templates
│       ├── base.html
│       ├── index.html
│       ├── application_detail.html
│       └── edit_application.html
│   └── static/           # Static files (CSS, JS)
│       └── style.css
├── backups/
│   └── .gitkeep          # Ensures the backups directory can be tracked if empty (if file exists)
├── scripts/
│   └── db_volume.sh      # Example script (if it exists)
├── Dockerfile            # Dockerfile for the FastAPI application
├── docker-compose.yml    # Docker Compose configuration
├── requirements.txt      # Python dependencies
├── .gitignore            # Specifies intentionally untracked files
└── README.md             # This file
```

## Future Considerations / Potential Improvements

*   **Database Migrations:** Implement Alembic for robust schema management.
*   **Deleting Applications/Notes:** Add UI and backend logic for deletion.
*   **Enhanced Error Handling:** Display user-friendly validation errors on forms.
*   **Pagination:** For long lists of applications or notes.
*   **User Authentication:** If multi-user capabilities are needed.
*   **Testing:** Implement unit and integration tests. 