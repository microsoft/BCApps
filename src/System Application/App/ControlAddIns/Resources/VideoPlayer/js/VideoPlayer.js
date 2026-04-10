"use strict";

var videoPlayerControlId = "videoPlayerControl";

function RaiseAddInReady() {
    CreateVideoContainer();
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod("AddInReady", null);
}

function CreateVideoContainer() {
    var videoContainer = document.createElement("iframe");
    videoContainer.setAttribute("id", videoPlayerControlId);
    videoContainer.classList.add("centered");
    videoContainer.setAttribute("marginheight", 0);
    videoContainer.setAttribute("marginwidth", 0);
    videoContainer.setAttribute("frameborder", 0);
    videoContainer.setAttribute("scrolling", 'no');
    document.getElementById("controlAddIn").appendChild(videoContainer);
}

function SetWidth(width) {
    var videoPlayer = GetVideoContainer();
    videoPlayer.setAttribute("width", width);
    videoPlayer.style.marginLeft = -width / 2 + "px";
}

function SetHeight(height) {
    var videoPlayer = GetVideoContainer();
    videoPlayer.setAttribute("height", height);
    videoPlayer.style.marginTop = -height / 2 + "px";
}

function SetFrameAttribute(attributeName, attributeValue) {
    var videoPlayer = GetVideoContainer();
    videoPlayer.setAttribute(attributeName, attributeValue);
}

function RemoveAttribute(attributeName) {
    var videoPlayer = GetVideoContainer();
    videoPlayer.removeAttribute(attributeName);
}

function GetVideoContainer() {
    return document.getElementById(videoPlayerControlId);
}