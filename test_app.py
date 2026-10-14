
from app import get_app_message


def test_app_message():
    assert get_app_message() == (
        "Streamlit AWS DevOps application is running."
    )
