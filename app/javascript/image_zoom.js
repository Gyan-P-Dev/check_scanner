document.addEventListener("turbo:load", function () {
  const images = document.querySelectorAll(".zoomable-image");
  const zoomModal = document.getElementById("zoom-modal");
  const zoomedImage = document.getElementById("zoomed-image");

  if (!zoomModal || !zoomedImage) {
    console.warn("Zoom modal elements not found!");
    return;
  }

  images.forEach((img) => {
    img.addEventListener("click", function () {
      zoomedImage.src = this.dataset.zoom;
      zoomModal.style.display = "block";
    });
  });

  zoomModal.addEventListener("click", function () {
    this.style.display = "none";
  });
});

function updateLocalTimes() {
  document.querySelectorAll(".local-time").forEach((td) => {
    const utcTime = td.dataset.time;
    if (!utcTime) return;

    const localDate = new Date(utcTime);
    td.textContent = localDate.toLocaleString(undefined, {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
      hour12: true,
    });
  });
}

document.addEventListener("DOMContentLoaded", updateLocalTimes);
document.addEventListener("turbo:load", updateLocalTimes);
document.addEventListener("turbo:render", updateLocalTimes);
