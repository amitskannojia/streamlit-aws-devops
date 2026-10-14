from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent


def test_app_file_exists():
    assert (PROJECT_ROOT / "app.py").is_file()


def test_requirements_file_exists():
    assert (PROJECT_ROOT / "requirements.txt").is_file()


def test_dockerfile_exists():
    assert (PROJECT_ROOT / "Dockerfile").is_file()


def test_app_contains_streamlit():
    app_content = (PROJECT_ROOT / "app.py").read_text(encoding="utf-8")
    assert "streamlit" in app_content.lower()

