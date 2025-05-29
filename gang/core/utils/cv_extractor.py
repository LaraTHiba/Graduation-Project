import logging
from typing import Optional

logger = logging.getLogger(__name__)

# Try to import required libraries
try:
    import PyPDF2
    PDF_SUPPORT = True
except ImportError:
    PDF_SUPPORT = False
    logger.warning("PyPDF2 not installed. PDF extraction will not be available.")

try:
    import docx
    DOCX_SUPPORT = True
except ImportError:
    DOCX_SUPPORT = False
    logger.warning("python-docx not installed. DOCX extraction will not be available.")

def extract_text_from_pdf(file) -> str:
    """Extract text from a PDF file."""
    if not PDF_SUPPORT:
        logger.warning("PDF extraction not available - PyPDF2 not installed")
        return ""
    
    try:
        pdf_reader = PyPDF2.PdfReader(file)
        text = ""
        for page in pdf_reader.pages:
            text += page.extract_text() + "\n"
        return text
    except Exception as e:
        logger.error(f"Error extracting text from PDF: {str(e)}")
        return ""

def extract_text_from_docx(file) -> str:
    """Extract text from a DOCX file."""
    if not DOCX_SUPPORT:
        logger.warning("DOCX extraction not available - python-docx not installed")
        return ""
    
    try:
        doc = docx.Document(file)
        text = ""
        for paragraph in doc.paragraphs:
            text += paragraph.text + "\n"
        return text
    except Exception as e:
        logger.error(f"Error extracting text from DOCX: {str(e)}")
        return ""

def extract_cv_text(file) -> str:
    """Extract text from a CV file (PDF or DOCX)."""
    filename = file.name.lower()
    
    if filename.endswith('.pdf'):
        return extract_text_from_pdf(file)
    elif filename.endswith(('.doc', '.docx')):
        return extract_text_from_docx(file)
    else:
        logger.warning(f"Unsupported file type: {filename}")
        return "" 