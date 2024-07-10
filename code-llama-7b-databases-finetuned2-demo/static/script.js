function updateForm() {
    const mode = document.getElementById('mode-select').value;
    const sqlFields = document.getElementById('sql-fields');
    const textFields = document.getElementById('text-fields');
    const fileFields = document.getElementById('file-fields');

    sqlFields.style.display = 'none';
    textFields.style.display = 'none';
    fileFields.style.display = 'none';

    if (mode === 'sql') {
      sqlFields.style.display = 'block';
    } else if (mode === 'text') {
      textFields.style.display = 'block';
    } else if (mode === 'file') {
      fileFields.style.display = 'block';
    }
}

const toggleSettingsBtn = document.getElementById("toggle-settings-btn");
toggleSettingsBtn.addEventListener("click", function(event) {
  event.preventDefault();

  const advancedSettingsDiv = document.getElementById("advanced-settings");

  if (advancedSettingsDiv.style.display === "none") {
    advancedSettingsDiv.style.display = "block";
    toggleSettingsBtn.textContent = "Hide Advanced Settings";
  } else {
    advancedSettingsDiv.style.display = "none";
    toggleSettingsBtn.textContent = "Advanced Settings";
  }
});

const showLoading = () => {
  document.getElementById('loading-overlay').style.display = 'flex';
};

const hideLoading = () => {
  document.getElementById('loading-overlay').style.display = 'none';
};

const sendRequest = async (request, mode) => {
  showLoading();

  try {
    let response;
    if (mode !== "file") {
      response = await fetch('/predict', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(request)
      });
    } else {
      const formData = new FormData();

      // Append all properties of the request object to the FormData
      for (const key in request) {
        if (request.hasOwnProperty(key)) {
          formData.append(key, request[key]);
        }
      }

      response = await fetch('/predict_batch', {
        method: 'POST',
        body: formData
      });
    }

    if (!response.ok) {
      throw new Error('Network response was not ok');
    }

    const jsonResponse = await response.json();

    // Check if the response is an array and handle accordingly
    let contentList = null;
    if (Array.isArray(jsonResponse)) {
      if (jsonResponse.length > 1) {
        contentList = document.createElement('ol');
        jsonResponse.forEach(item => {
          if (item.content) {
            let listItem = document.createElement('li');
            listItem.textContent = item.content;
            contentList.appendChild(listItem);
          }
        });
      } else {
        contentList = jsonResponse[0]?.content || jsonResponse.content || ''
      }
    }
    
    return contentList;
  } catch (error) {
    console.error('Error:', error);
  } finally {
    hideLoading();
  }
};

const textGenForm = document.querySelector(".text-gen-form");
const textGenParagraph = document.querySelector(".text-gen-output");
const fileInput = document.getElementById("file-input");
//const showEmail = document.getElementById('send-email');
//const emailPrompt = document.getElementById('email-prompt');

textGenForm.addEventListener("submit", async (event) => {
  event.preventDefault();

  const mode = document.getElementById("mode-select").value;

  request = {}

  if (mode === "file") {
    if (fileInput.files.length > 0) {
      const file = fileInput.files[0];
      request.json_file = file;
    } else {
      textGenParagraph.textContent = "Please upload a file.";
      return;
    }
  } else {
    request.context = document.getElementById(`${mode}-context`).value;
    request.prompt = document.getElementById(`${mode}-prompt`).value;

    if (request.context == "") {
      textGenParagraph.textContent = "Please enter a context.";
      return;
    } 

    if (request.prompt == "") {
      textGenParagraph.textContent = "Please enter a prompt.";
      return;
    } 
  }

  /*
  if (showEmail.checked) {
    if (emailPrompt.value === "") {
      textGenParagraph.textContent = "Please enter a valid email address.";
      return;
    } else {
      request.email = emailPrompt.value;
    }
  }
  */

  request.tokenize = document.getElementById("tokenize").checked;
  request.add_generation_prompt = document.getElementById("add-generation-prompt").checked;
  request.max_new_tokens = document.getElementById("max-new-tokens").value;
  request.do_sample = document.getElementById("do-sample").checked;
  request.temperature = document.getElementById("temperature").value;
  request.top_k = document.getElementById("top-k").value;
  request.top_p = document.getElementById("top-p").value;

  textGenParagraph.append(await sendRequest(request, mode));
});

/*
document.getElementById('send-email').addEventListener('change', function() {
  const showEmailDiv = document.getElementById('show-email');
  if (this.checked) {
      showEmailDiv.style.display = 'block';
  } else {
      showEmailDiv.style.display = 'none';
  }
});*/