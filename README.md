# Emergency App

A Flutter mobile application designed to assist users during emergencies by providing quick access to essential services and information, powered by AI and real-time location features.

## Problem Statement

During emergency situations, bystanders often lack the knowledge or confidence to provide appropriate assistance to victims. Key challenges include:

1. **Lack of immediate medical knowledge**: Most people are not trained in first aid or emergency response.
2. **Confusion about symptoms**: Bystanders struggle to identify symptoms and determine the appropriate course of action.
3. **Delayed professional help**: Critical time is lost while waiting for emergency services to arrive.
4. **Communication barriers**: Difficulty in effectively communicating the emergency situation and location to emergency services.

The Emergency App addresses these challenges by empowering users with AI-guided assistance, instructional content, and rapid emergency contact features, potentially saving lives in critical situations when every second counts.

## Features

1. **AI Chatbot**  
   An intelligent chatbot powered by Dialogflow to understand the user's condition through symptom-based conversation and provide relevant emergency advice or guidance.

2. **Video Assistance for Medical Emergencies**  
   Plays instructional videos tailored to the specific emergency—for example, different CPR videos for kids, men, and women to ensure inclusivity and accuracy.

3. **SOS System**  
   - Sends an SMS containing the user's current location to saved emergency contacts.
   - Alerts nearby ambulance services to ensure faster response in critical situations.
   - One-tap emergency calling to local emergency numbers.

4. **Emergency Information Repository**
   - First aid guides for common emergencies
   - Location-based emergency service contacts
   - Offline access to critical information

## Tech Stack

- **Frontend**: Flutter for cross-platform mobile development
- **AI Integration**: Dialogflow for natural language processing and chatbot capabilities
- **Location Services**: Geolocator for precise location tracking
- **Data Storage**: Shared Preferences for local storage of emergency contacts

## Screenshots

![WhatsApp Image 2025-05-16 at 10 37 34 AM (2)](https://github.com/user-attachments/assets/cd60b3c3-13f8-4102-91f7-3f0276e07a23)
![WhatsApp Image 2025-05-16 at 10 37 34 AM (1)](https://github.com/user-attachments/assets/1746d091-d11a-40a3-85ec-329c980cd144)
![WhatsApp Image 2025-05-16 at 10 37 34 AM](https://github.com/user-attachments/assets/8ad990ac-8407-4e70-87d4-c084c8c0ef97)
![WhatsApp Image 2025-05-16 at 10 37 35 AM (1)](https://github.com/user-attachments/assets/4b0fbef1-d550-4cd8-be93-9c750d535ddc)
![WhatsApp Image 2025-05-16 at 10 37 35 AM](https://github.com/user-attachments/assets/f4e94b94-61f2-41a6-8dcc-fead5de7fece)
![WhatsApp Image 2025-05-16 at 10 37 36 AM (1)](https://github.com/user-attachments/assets/8fd6fbd6-0938-477b-9176-c181f750def1)
![WhatsApp Image 2025-05-16 at 10 37 36 AM](https://github.com/user-attachments/assets/2c94b3b7-624e-4314-9d67-b7c739fb9b71)
![WhatsApp Image 2025-05-16 at 10 37 37 AM (1)](https://github.com/user-attachments/assets/4211bbb6-853f-4314-a579-3dc04e256faa)
![WhatsApp Image 2025-05-16 at 10 37 37 AM](https://github.com/user-attachments/assets/8a280139-966a-4a49-b890-9627a0ca1757)
![WhatsApp Image 2025-05-16 at 10 37 38 AM](https://github.com/user-attachments/assets/4394305c-417a-42ef-9e9c-fcaca4d1f4e5)



## Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/manvip28/emergency_app.git
   ```

2. **Navigate to the project directory**:
   ```bash
   cd emergency_app
   ```

3. **Install dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## Dependencies

- `flutter`: Core framework for building the application
- `geolocator`: For accessing device location
- `permission_handler`: To manage app permissions
- `just_audio`: For playing audio alerts
- `url_launcher`: For making calls and sending SMS
- `http`: For API communication
- `shared_preferences`: For local data storage
- `dialogflow_flutter`: For integrating Dialogflow AI chatbot
