from sqlalchemy.orm import Session
from sqlalchemy import desc
from . import models, schemas
from typing import List, Optional
from pydantic import HttpUrl

# --- Job Application CRUD --- 

def get_job_application(db: Session, application_id: int) -> Optional[models.JobApplication]:
    return db.query(models.JobApplication).filter(models.JobApplication.id == application_id).first()

def get_job_applications(db: Session, skip: int = 0, limit: int = 100) -> List[models.JobApplication]:
    return db.query(models.JobApplication).offset(skip).limit(limit).all()

def create_job_application(db: Session, application: schemas.JobApplicationCreate) -> models.JobApplication:
    app_data = application.model_dump()
    if isinstance(app_data.get("url"), HttpUrl):
        app_data["url"] = str(app_data["url"])
    
    db_application = models.JobApplication(**app_data)
    db.add(db_application)
    db.commit()
    db.refresh(db_application)
    return db_application

def update_job_application(db: Session, application_id: int, application_update: schemas.JobApplicationUpdate) -> Optional[models.JobApplication]:
    db_application = get_job_application(db, application_id)
    if db_application:
        update_data = application_update.model_dump(exclude_unset=True)
        if isinstance(update_data.get("url"), HttpUrl):
            update_data["url"] = str(update_data["url"])
            
        for key, value in update_data.items():
            setattr(db_application, key, value)
        db.commit()
        db.refresh(db_application)
    return db_application

def delete_job_application(db: Session, application_id: int) -> Optional[models.JobApplication]:
    db_application = get_job_application(db, application_id)
    if db_application:
        db.delete(db_application)
        db.commit()
    return db_application

# --- Note CRUD --- 

def create_note_for_application(db: Session, note: schemas.NoteCreate, application_id: int) -> models.Note:
    db_note = models.Note(**note.model_dump(), application_id=application_id)
    db.add(db_note)
    db.commit()
    db.refresh(db_note)
    return db_note

def get_notes_for_application(db: Session, application_id: int) -> List[models.Note]:
    return db.query(models.Note).filter(models.Note.application_id == application_id).order_by(desc(models.Note.id)).all() 