var controlAddIn = document.getElementById("controlAddIn");
controlAddIn.style.backgroundColor = "#79CACE";
controlAddIn.style.display = "flex";
controlAddIn.style.justifyContent = "center";
controlAddIn.style.alignItems = "center";
controlAddIn.style.maxHeight = "150px";
controlAddIn.insertAdjacentHTML('beforeend', '<img style="display:block; max-height:150px; object-fit:contain;" src="' +
        Microsoft.Dynamics.NAV.GetImageResource('resources/EarlyAccessPreview/EAPBanner.png') +
        '"/>');