var WelcomeWizardAddIn = function () {
    var notifyError = function(error,description) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ErrorOccurred', [error, description]);
    };
    return {
        notifyError: notifyError
    };
}();

var roleCenterTitle;
var roleCenterDesc;

function Initialize(titletxt, subtitletxt, explanationtxt, intro, introDescription, getStarted, getStartedDescription, getHelp, getHelpDescription, roleCenters, roleCentersDescription, roleCenter, legalDescription) {
    DrawCanvas();
    DrawLayout(titletxt, subtitletxt, explanationtxt, intro, introDescription, getStarted, getStartedDescription, getHelp, getHelpDescription, roleCenters, roleCentersDescription, roleCenter, legalDescription);
}


function DrawCanvas()
{
    document.getElementById("controlAddIn").innerHTML = "";

    var canvas = document.createElement('div');
    canvas.className = "mainCanvas";
    canvas.id = "mainCanvas";
    document.getElementById("controlAddIn").appendChild(canvas);
}

function DrawLayout(titletxt, subtitletxt, explanationtxt, intro, introDescription, getStarted, getStartedDescripion, getHelp, getHelpDescription, roleCenters, roleCentersDescription, roleCenter, legalDescription)
{
    roleCenterTitle = roleCenters;
    roleCenterDesc = roleCentersDescription;
    var canvas = document.getElementById("mainCanvas");

    var container = document.createElement('div');
    container.className = "container";
    container.id = "welcomeContainer";
    
    var bottomBorder = document.createElement('div');
    bottomBorder.className = "sectionborder";

    var welcomeDiv = document.createElement('div');
    welcomeDiv.id = "welcomeDivTag";
    welcomeDiv.className = "welcomediv";

    var title = document.createElement('div');
    title.className = "title titlefont";
    var t = document.createTextNode(titletxt);
    title.appendChild(t);

    var br = document.createElement('br');

    var subtitle = document.createElement('div');
    subtitle.className = "subtitle brandPrimary titlefont";
    t = document.createTextNode(subtitletxt);
    subtitle.appendChild(t);

    var explanationdiv = document.createElement('div');
    explanationdiv.id = "expDiv";

    var explanationdesc = document.createElement('div');
    explanationdesc.className = "explanation brandSecondary";
    t = document.createTextNode(explanationtxt);
    explanationdesc.appendChild(t);


    welcomeDiv.appendChild(title);
    welcomeDiv.appendChild(br);
    welcomeDiv.appendChild(subtitle);
    explanationdiv.appendChild(explanationdesc);
    welcomeDiv.appendChild(explanationdiv);

    var welcomeimageDiv = document.createElement('div');
    welcomeimageDiv.className = "welcomeimagediv";

    var imageDiv = document.createElement('div');
    var welcomeImg = document.createElement("img");
    welcomeImg.className = "welcomeimage";
    welcomeImg.id = "welcomePic";
    welcomeImg.alt = "";
    var imageUrl = Microsoft.Dynamics.NAV.GetImageResource('01_welcome.png');
    welcomeImg.src = imageUrl;

    imageDiv.appendChild(welcomeImg);
    welcomeimageDiv.appendChild(imageDiv);

    bottomBorder.appendChild(welcomeDiv);
    bottomBorder.appendChild(welcomeimageDiv);

    container.appendChild(bottomBorder);

    var links = document.createElement('div');
    links.className = "links";
    links.id = "linksDiv";
    
    tile1 = document.createElement('button');
    tile1.className = "tile tilemarginright button";
    tile1.id = "tile1Button";

    var tile1Description = document.createElement('div');
    tile1Description.className = "tileDescription";
    tile1Description.id = "tileDescription1";
    t = document.createTextNode(intro);
    tile1Description.appendChild(t);

    var tile1SubDescription = document.createElement('div');
    tile1SubDescription.className = "segoeRegularfont brandSecondary";
    tile1SubDescription.id = "tileSubDescription1";
    t = document.createTextNode(introDescription);
    tile1SubDescription.appendChild(t);

    var tile1Img = document.createElement("img");
    tile1Img.id = "introductionImg";
    tile1Img.alt = "";
    imageUrl = Microsoft.Dynamics.NAV.GetImageResource('02_introduction.png');
    tile1Img.src = imageUrl;

    tile1.appendChild(tile1Description);
    tile1.appendChild(tile1SubDescription);
    tile1.appendChild(tile1Img);

    tile2 = document.createElement('button');
    tile2.className = "tile tilemarginright button";
    tile2.id = "tile2Button";

    var tile2Description = document.createElement('div');
    tile2Description.className = "tileDescription";
    tile2Description.id = "tileDescription2";
    t = document.createTextNode(getStarted);
    tile2Description.appendChild(t);

    var tile2SubDescription = document.createElement('div');
    tile2SubDescription.className = "segoeRegularfont brandSecondary";
    tile2SubDescription.id = "tileSubDescription2";
    t = document.createTextNode(getStartedDescripion);
    tile2SubDescription.appendChild(t);

    var tile2Img = document.createElement("img");
    tile2Img.id = "outlookImg";
    tile2Img.alt = "";
    imageUrl = Microsoft.Dynamics.NAV.GetImageResource('03_outlook.png');
    tile2Img.src = imageUrl;

    tile2.appendChild(tile2Description);
    tile2.appendChild(tile2SubDescription);
    tile2.appendChild(tile2Img);

    tile3 = document.createElement('button');
    tile3.className = "tile tilemarginright button";
    tile3.id = "tile3Button";

    var tile3Description = document.createElement('div');
    tile3Description.className = "tileDescription";
    tile3Description.id = "tileDescription3";
    t = document.createTextNode(getHelp);
    tile3Description.appendChild(t);

    var tile3SubDescription = document.createElement('div');
    tile3SubDescription.className = "segoeRegularfont tooltip brandSecondary";
    tile3SubDescription.id = "tileSubDescription3";
    tile3SubDescriptionText = getHelpDescription.length > 36 ? getHelpDescription.substring(0,36) + "..." : getHelpDescription;
    t = document.createTextNode(tile3SubDescriptionText);
    tile3SubDescription.appendChild(t);
    var span = document.createElement('span');
    span.className = "tooltiptext";
    span.appendChild(document.createTextNode(getHelpDescription));

    var tile3Img = document.createElement("img");
    tile3Img.id = "extensionsImg";
    tile3Img.alt = "";
    imageUrl = Microsoft.Dynamics.NAV.GetImageResource('04_extensions.png');
    tile3Img.src = imageUrl;

    tile3.appendChild(tile3Description);
    tile3.appendChild(tile3SubDescription);
    tile3.appendChild(tile3Img);

    tile4 = document.createElement('div');
    tile4.className = "tile";
    tile4.id = 'tile4';

    var button = CreateRoleCenterSection();

    tile4.appendChild(button);
    var roleCenterDiv = CreateRoleCenterDiv(roleCenter);
    tile4.appendChild(roleCenterDiv);

    links.appendChild(tile1);
    links.appendChild(tile2);
    links.appendChild(tile3);

    container.appendChild(links);

    links = document.createElement('div');
    links.id = "thumbnailLinksDiv"
    links.className = "links";

    var legalDescriptionDiv = document.createElement('div');
    legalDescriptionDiv.id = 'legalDescriptionDiv';
    legalDescriptionDiv.className = "legalDescription";
    var legalDiv = document.createElement('div');
    legalDiv.className = "segoeRegularfont brandSecondary legalDescriptionHeight";
    legalDiv.id = 'legalDiv';
    t = document.createTextNode(legalDescription);
    legalDiv.appendChild(t);

    legalDescriptionDiv.appendChild(legalDiv);

    links.appendChild(legalDescriptionDiv);

    container.appendChild(links);

    canvas.appendChild(container);

    $('#welcomeContainer').attr('role', 'dialog');
    $('#welcomeContainer').attr('aria-describedby', 'welcomeDivTag');
    $('#welcomePic').attr('role', 'presentation');
    $('#tile1Button').attr('aria-labelledby', 'tileDescription1 tileSubDescription1');
    $('#tile2Button').attr('aria-labelledby', 'tileDescription2 tileSubDescription2');
    $('#tile3Button').attr('aria-labelledby', 'tileDescription3 tileSubDescription3');
    $('#legalDescriptionDiv').attr('aria-labelledby', 'legalDiv'); 
    
    $("#tile1Button").click(function(){ThumbnailClick(1);});
    $("#tile2Button").click(function(){ThumbnailClick(2);});
    $("#tile3Button").click(function(){ThumbnailClick(3);});
}

function ThumbnailClick(id)
{ 
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ThumbnailClicked', [id]);
}

function RoleCenterClick()
{ 
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('RoleCenterClicked', [1]);
}

function UpdateProfileId(profileId)
{ 
}

function CreateRoleCenterSpan()
{
    var checkboxSpan = document.createElement('span');
    checkboxSpan.className = "checkbox";
    var checkboxImg = document.createElement('img');
    checkboxImg.id = "checkboxImg";
    checkboxImg.alt = "";
    var imageUrl = Microsoft.Dynamics.NAV.GetImageResource('GoChecked.png');
    checkboxImg.src = imageUrl;
    checkboxSpan.appendChild(checkboxImg);
    return checkboxSpan;
}

function CreateRoleCenterSection()
{

    var button = document.createElement('button');
    button.className = "button";
    button.id = "tile4Button";

    var tile4Description = document.createElement('div');
    tile4Description.className = "tileDescription";
    tile4Description.id = "tileDescription4";
    t = document.createTextNode(roleCenterTitle);
    tile4Description.appendChild(t);

    var tile4SubDescription = document.createElement('div');
    tile4SubDescription.className = "segoeRegularfont brandSecondary";
    tile4SubDescription.id = "tileSubDescription4";
    t = document.createTextNode(roleCenterDesc);
    tile4SubDescription.appendChild(t);

    var tile4Img = document.createElement("img");
    tile4Img.id = "roleCenterImg";
    tile4Img.alt = "";
    imageUrl = Microsoft.Dynamics.NAV.GetImageResource('05_rolecenter.png');
    tile4Img.src = imageUrl;

    button.appendChild(tile4Description);
    button.appendChild(tile4SubDescription);
    button.appendChild(tile4Img);
    return button;
}

function CreateRoleCenterDiv(roleCenter)
{
    var roleCentDiv = document.createElement('div');
    roleCentDiv.id = 'roleCenterName';
    roleCentDiv.className = "segoeRegularfont brandPrimary truncate";
    
    var checkboxSpan = CreateRoleCenterSpan();
    roleCentDiv.appendChild(checkboxSpan);
    
    t = document.createTextNode('  ' + roleCenter);
    roleCentDiv.appendChild(t);
    return roleCentDiv;
}
