document.addEventListener("DOMContentLoaded", function () {
  const checkForm = document.getElementById("check-form");

  checkForm.addEventListener("submit", function (event) {
    event.preventDefault();

    fetch(this.action, {
      method: "POST",
      body: new FormData(this),
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
      },
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.company_id) {
          document.getElementById("companySelect").value = data.company_id;
        }
      });
  });
});
