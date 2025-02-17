---
layout: post
title: How to Send Email via Static Site Using Google Apps Script
date: 2025-02-17 20:37:00 +0100
description: You’ll find this post in your `_posts` directory. Go ahead and edit it and re-build the site to see your changes. # Add post description (optional)
img: email-sending.webp # Add image post (optional)
fig-caption: # Add figcaption (optional)
tags: [Email, Google Apps Script]
---

### **How to Send Email via Static Site Using Google Apps Script**

This approach leverages Google Apps Script to handle the form submission and send emails. Here's how to integrate it into your static site.

---

### **1. Create the Google Apps Script Web App**

1. **Go to the Google Apps Script Editor:**
   - Open [Google Apps Script](https://script.google.com).
   - Click `New Project`.

2. **Add the Script Code:**
   - Paste the following code in the script editor:

```javascript
function doPost(e) {
  var params = e.parameter; // Extract form data

  var to = params.to || "marko.milic@yahoo.com";
  var subject = params.subject || "New Contact Form Submission";
  var name = params.name || "N/A";
  var email = params.email || "N/A";
  var phone = params.phone || "N/A";
  var message = params.message || "N/A";

  // Send the email
  MailApp.sendEmail({
    to: to,
    subject: subject,
    htmlBody: "<p><b>Name:</b> " + name + "<br><b>Email:</b> " + email + "<br><b>Phone:</b> " + phone + "<br><b>Message:</b> " + message + "</p>"
  });

  // Respond with a success message
  var response = ContentService.createTextOutput(JSON.stringify({
    status: "success",
    message: "Email sent successfully"
  }));
  response.setMimeType(ContentService.MimeType.JSON);

  return response;
}
```

3. **Deploy as a Web App:**
   - Click `Deploy` > `New Deployment` > `Select type` > `Web app`.
   - Set access permissions:
     - **Execute as**: `Me (your Google account)`
     - **Who has access**: `Anyone`
   - Click **Deploy**. You'll receive a URL for your web app.

---

### **2. Integrate the Form with the Static Site**

Your static site will use AJAX (through jQuery) to submit the form data to the Google Apps Script web app and send the email.

1. **HTML Form (Example)**

Create a simple form in your HTML for collecting contact data:

```html
<form id="contactForm">
  <input type="text" id="name" name="name" placeholder="Your Name" required>
  <input type="email" id="email" name="email" placeholder="Your Email" required>
  <input type="tel" id="phone" name="phone" placeholder="Your Phone" required>
  <textarea id="message" name="message" placeholder="Your Message" required></textarea>
  <button type="submit" id="sendMessageButton">Send Message</button>
</form>
<div id="success"></div>
```

2. **AJAX Request for Sending the Form Data**

Modify the JavaScript to process form submissions using AJAX and send the data to the Google Apps Script web app:

```javascript
<script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
<script>
$(function () {
  $("#contactForm").on('submit', function (e) {
    e.preventDefault(); // Prevent default form submission

    // Collect form data
    var name = $("#name").val();
    var email = $("#email").val();
    var phone = $("#phone").val();
    var message = $("#message").val();

    // AJAX request
    $.ajax({
      url: "YOUR_GOOGLE_APPS_SCRIPT_URL",  // Replace with your Google Apps Script URL
      type: "POST",
      data: {
        name: name,
        email: email,
        phone: phone,
        message: message
      },
      contentType: "application/x-www-form-urlencoded",
      success: function (response) {
        if (response.status === "success") {
          $("#success").html("<div class='alert alert-success'>Message sent successfully!</div>");
        } else {
          $("#success").html("<div class='alert alert-danger'>There was an error sending the message.</div>");
        }
      },
      error: function () {
        $("#success").html("<div class='alert alert-danger'>An error occurred. Please try again later.</div>");
      }
    });
  });
});
</script>
```

- **Replace `YOUR_GOOGLE_APPS_SCRIPT_URL`** with the actual URL of your deployed Google Apps Script web app.

---

### **3. Testing the Form**

Once everything is set up:
- Test the form on your static site.
- Fill in the form and submit.
- Check your inbox to confirm the message was sent successfully.

---

### **4. Security Considerations**

1. **Protect Email Address:**
   - You should consider adding CAPTCHA (like reCAPTCHA) to prevent spam submissions.
   
2. **Limit Access:**
   - While the web app is set to "Anyone," it’s a good practice to add additional authentication or validation methods (e.g., checking referrer or IP addresses).

---

### **Summary**

- **Google Apps Script** acts as the backend to send emails.
- **AJAX** is used to send form data from the static site to the Google Apps Script web app.

By following these steps, you can easily integrate a contact form that sends emails directly from your static website using Google Apps Script!

