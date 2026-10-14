import streamlit as st
from datetime import datetime, timezone

st.set_page_config(
    page_title="AWS DevOps Dashboard",
    page_icon="🚀",
    layout="wide",
)

st.title("AWS DevOps Dashboard")
st.write("Streamlit application deployed on Amazon EKS.")

col1, col2, col3 = st.columns(3)

with col1:
    st.metric("Application", "Streamlit")

with col2:
    st.metric("Platform", "Amazon EKS")

with col3:
    st.metric("Deployment", "Docker + Kubernetes")

st.subheader("Deployment Status")
st.success("The application is running.")

st.write("Current UTC time:")
st.code(datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC"))

st.subheader("DevOps Pipeline")
st.write(
    "GitHub → Jenkins → Docker → Amazon ECR → Amazon EKS → "
    "Kubernetes Service → AWS Application Load Balancer"
)

st.info("This demo does not require an OpenAI API key.")
