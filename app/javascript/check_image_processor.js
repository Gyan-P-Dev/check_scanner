document.addEventListener("DOMContentLoaded", function () {
  let imageInput = document.getElementById("check-image");

  // Camera Elements
  let startCameraButton = document.getElementById("start-camera");
  let captureButton = document.getElementById("capture-photo");
  let cancelCameraButton = document.getElementById("cancel-camera");
  let video = document.getElementById("camera-preview");
  let canvas = document.getElementById("captured-frame");
  let capturedImage = document.getElementById("captured-image");

  let stream = null;

  // **Handle File Upload**
  imageInput.addEventListener("change", function (event) {
    resetCamera(); // Clear camera if a new file is uploaded
    if (imageInput.files.length > 0) {
      let file = imageInput.files[0];
      previewImage(file); // Display the uploaded image
      processImage(file); // Process image via OCR
    }
  });

  // **Start Camera**
  startCameraButton.addEventListener("click", async function () {
    resetPreview(); // Clear previous image

    try {
      stream = await navigator.mediaDevices.getUserMedia({ video: true });
      video.srcObject = stream;
      video.style.display = "block";
      captureButton.style.display = "inline-block";
      cancelCameraButton.style.display = "inline-block";
      startCameraButton.style.display = "none";
    } catch (error) {
      console.error("Camera access denied:", error);
      alert("Could not access camera. Please allow camera permissions.");
    }
  });

  // **Capture Image**
  captureButton.addEventListener("click", function () {
    let context = canvas.getContext("2d");
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    context.drawImage(video, 0, 0, canvas.width, canvas.height);

    let imageData = canvas.toDataURL("image/png");

    stopCamera(); // Stop the camera after capture

    previewCapturedImage(imageData);

    // Convert Data URL to Blob and assign to file input
    fetch(imageData)
      .then((res) => res.blob())
      .then((blob) => {
        let file = new File([blob], "captured-check.png", {
          type: "image/png",
        });
        let dataTransfer = new DataTransfer();
        dataTransfer.items.add(file);
        imageInput.files = dataTransfer.files;

        // Process the captured image
        processImage(file);
      });
  });

  // **Cancel Camera**
  cancelCameraButton.addEventListener("click", function () {
    stopCamera();
  });

  // **Stop Camera Function**
  function stopCamera() {
    if (stream) {
      stream.getTracks().forEach((track) => track.stop());
    }
    video.style.display = "none";
    captureButton.style.display = "none";
    cancelCameraButton.style.display = "none";
    startCameraButton.style.display = "inline-block";
  }

  // **Reset Preview When Opening Camera**
  function resetPreview() {
    capturedImage.src = "";
    capturedImage.style.display = "none";
    imageInput.value = ""; // Clear file input when opening the camera
  }

  // **Reset Camera & Captured Image**
  function resetCamera() {
    stopCamera();
    capturedImage.src = "";
    capturedImage.style.display = "none";
  }

  // **Preview Uploaded Image**
  function previewImage(file) {
    let reader = new FileReader();
    reader.onload = function (e) {
      capturedImage.src = e.target.result;
      capturedImage.style.display = "block";
    };
    reader.readAsDataURL(file);
  }

  // **Preview Captured Image**
  function previewCapturedImage(imageData) {
    capturedImage.src = imageData;
    capturedImage.style.display = "block";
  }

  // **Process Image via OCR**
  function processImage(file) {
    let formData = new FormData();
    formData.append("image", file);
    let csrfToken = document.querySelector('meta[name="csrf-token"]').content;

    fetch("/extract_attributes", {
      method: "POST",
      body: formData,
      headers: { "X-CSRF-Token": csrfToken },
    })
      .then((response) => response.json())
      .then((data) => {
        let isValid = true; // Assume image is valid initially

        // Validate company name
        if (data.company_name) {
          let companySelect = document.getElementById("company-select");
          let option = [...companySelect.options].find(
            (opt) => opt.text.trim() === data.company_name.trim()
          );

          if (option) {
            companySelect.value = option.value;
          } else {
            let newOption = document.createElement("option");
            newOption.value = data.company_id;
            newOption.text = data.company_name;
            companySelect.appendChild(newOption);
            companySelect.value = data.company_id;
          }
        } else {
          isValid = false;
        }

        // Validate check number
        if (data.check_number) {
          document.getElementById("check-number").value = data.check_number;
        } else {
          isValid = false;
        }

        // Validate invoice numbers
        if (data.invoice_numbers.length > 0) {
          document.getElementById("invoice-numbers").value =
            data.invoice_numbers.join(", ");
        } else {
          isValid = false;
        }

        // Show error if image is invalid
        if (!isValid) {
          alert("Invalid image. Please try again with a valid check image.");
          resetPreview(); // Reset fields if image is invalid
        }
      })
      .catch((error) => {
        alert("Error processing image. Please try again.");
        resetPreview();
      });
  }
});
