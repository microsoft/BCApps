var jsonContent;
var jsonPageData;
var actionLabel;
var pageDescription;
var disclaimerText;
var currentProfileId;
var currentSelectedIndex;

function LoadRoleCenterFromJson(jsonText){
    jsonContent = JSON.parse(jsonText);
    DrawFeatureContent();
}

function LoadPageDataFromJson(jsonText){
    jsonPageData = JSON.parse(jsonText);
    DrawPage();
} 

function GetCurrentProfileId(profileId){
    profileId = currentProfileId;
    return currentProfileId;
}

function SelectDropdownItem(index) {
    var dropdownItems = document.getElementById("select");
    for (var i = 0; i < dropdownItems.options.length; ++i) {
        if (dropdownItems.options[i].value == index.toString()) {
            dropdownItems.options[i].selected = true;
        }
    }
}

function SetCurrentProfileId(ProfileId) {
    currentProfileId = ProfileId;
    var index = jsonPageData.DropContent.map(function (d) { return d['Name']; }).indexOf(currentProfileId);
    currentSelectedIndex = index;

    SelectDropdownItem(currentSelectedIndex);
}

function DrawPage() {
    DrawCanvas();
    DrawDropdown();
    DrawFooter();
}

function ReplaceFeaturesContent() {
    $("#featuretable").remove();
    InsertFeaturesContent();
}

function InsertFeaturesContent() {
    var features = jsonContent;

    var tableDiv = document.createElement("div");
    tableDiv.className = "tableDiv";
    tableDiv.id = "featuretable";

    var table = document.createElement("table");
    table.className = "ms-Table ms-Table--fixed";
    tableDiv.appendChild(table);

    var thead = document.createElement("thead");
    table.appendChild(thead);
    var theadRow = document.createElement("tr");
    thead.appendChild(theadRow);

    for (var i = 0; i < features.length; i++) {
        var th = document.createElement("th");
        th.className = "tableheader ms-fontSize-mPlus ms-fontWeight-semibold";
        var callOutDiv = document.createElement("div");
        callOutDiv.textContent = features[i].name;
        th.appendChild(callOutDiv);
        theadRow.appendChild(th);
    }

    var expand = true;
    var index = 0;
    var tbody = document.createElement("tbody");
    table.appendChild(tbody);

    while (expand) {
        expand = false;
        var tRow = document.createElement("tr");
        tbody.appendChild(tRow);
        for (var j = 0; j < features.length; j++) {
            var td = document.createElement("td");
            if (index < features[j].rows.length) {
                expand = true;
                td.className = "type2 ms-fontSize-m ms-fontWeight-regular";
                callOutDiv = CreateCalloutElement(features[j].rows[index].name, features[j].rows[index].tooltip, j + 4, 'td' + index + j);
                td.appendChild(callOutDiv);
            }
            tRow.appendChild(td);
        }
        index++;
    }
        
    var pageHeader = document.getElementById("pageheader");
    pageHeader.parentNode.insertBefore(tableDiv, pageHeader.nextSibling);

    var Callouts = document.querySelectorAll(".msCalloutDiv");
    for (var k = 0; k < Callouts.length; k++) {
        var callout = Callouts[k];
        var CalloutTriggerElement = callout.querySelector(".calloutlabeldiv .calloutspandiv");
        var CalloutElement = callout.querySelector(".ms-Callout");
        new fabric['Callout'](
            CalloutElement,
            CalloutTriggerElement,
            "right"
        );
    }
}

function DrawFeatureContent() {
    if (document.getElementById("featuretable") != null) {
        ReplaceFeaturesContent();
    }
    else {
        InsertFeaturesContent();
    }
}

function DrawCanvas()
{
    document.getElementById("controlAddIn").innerHTML = "";

    var canvas = document.createElement('div');
    canvas.className = "mainCanvas";
    canvas.id = "mainCanvas";
    document.getElementById("controlAddIn").appendChild(canvas);
}

function OnChangeSelection()
{
    var selectedValue = document.getElementById("select").value;
    currentSelectedIndex = parseInt(selectedValue);
    currentProfileId = jsonPageData.DropContent[selectedValue].Name;
    SetCurrentProfileId(currentProfileId);
    Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnProfileSelected', [currentProfileId]);
}
function DrawDropdown() {
    var canvas = document.getElementById("mainCanvas");

    var headerDiv = document.createElement("div");
    headerDiv.className = "header";
    headerDiv.id = "pageheader";
    canvas.appendChild(headerDiv);

    var titleLabel = document.createElement("label");
    titleLabel.className = "ms-Label";
    titleLabel.id = "dropdownLabel";
    titleLabel.textContent = jsonPageData.HeaderLabel;
    headerDiv.appendChild(titleLabel);

    var dropDownDiv = document.createElement("div");
    dropDownDiv.className = "ms-Dropdown";
    headerDiv.appendChild(dropDownDiv);
    var select = document.createElement("select");
    select.id = "select";
    select.tabIndex = 3;
    select.setAttribute("onChange", "OnChangeSelection()");
    select.setAttribute("aria-labelledby", "dropdownLabel");

    for (var i = 0; i < jsonPageData.DropContent.length; i++) {
        var option = document.createElement("option");
        option.value = i;
        option.text = jsonPageData.DropContent[i].Description;
        select.options.add(option);
    }
    dropDownDiv.appendChild(select);

    //var desc = document.createElement("label");
    //desc.className = "ms-Label";
    //desc.id = "actiondesc";
    //desc.textContent = jsonPageData.ActionDescription;
    //headerDiv.appendChild(desc);

    var button = document.createElement("button");
    button.className = "ms-Button";
    button.setAttribute("aria-labelledby", "actiondesc");
    button.tabIndex = 4;
    headerDiv.appendChild(button);

    var buttonSpan = document.createElement("span");
    buttonSpan.className = "ms-Button-label";
    buttonSpan.textContent = jsonPageData.DefaultActionLabel;
    button.appendChild(buttonSpan);

    button.addEventListener("click", function () {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('OnAcceptAction', null);
    });
}

function DrawFooter()
{
    var canvas = document.getElementById("mainCanvas");
    var footer = document.createElement("div");
    footer.className = "footer";
    footer.id = "footer";
    canvas.appendChild(footer);

    var messageBar = document.createElement("div");
    messageBar.className = "ms-MessageBar ms-MessageBar--warning";

    var messageBarContent = document.createElement("div");
    messageBarContent.className = "ms-MessageBar-content";

    var messageBarIconDiv = document.createElement("div");
    messageBarIconDiv.className = "ms-MessageBar-icon";

    var messageBarIcon = document.createElement("i");
    messageBarIcon.className = "ms-Icon ms-Icon--Important";

    messageBarIconDiv.appendChild(messageBarIcon);

    var messageBarText = document.createElement("div");
    messageBarText.className = "ms-MessageBar-text";
    messageBarText.textContent = jsonPageData.DisclaimerText;

    messageBarContent.appendChild(messageBarIconDiv);
    messageBarContent.appendChild(messageBarText);

    messageBar.appendChild(messageBarContent);

    footer.appendChild(messageBar);
}

/*
<div class="msCalloutDiv">
    <div class="ms-Callout is-hidden">
        <div class="ms-Callout-main">
            <div class="ms-Callout-header">
                <p class="ms-Callout-title">All of your favorite people</p>
            </div>
            <div class="ms-Callout-inner">
                <div class="ms-Callout-content">
                    <p class="ms-Callout-subText ms-Callout-subText--">tooltip.</p>
                </div>
            </div>
        </div>
    </div>
    <div class="calloutlabeldiv">
        <div class="calloutspandiv">
            <a>Open Callout</a>
        </div>
    </div>
</div>
*/
function CreateCalloutElement(featureName, featureDescription, tabIndex, cellId) {
    var callOutDiv = document.createElement("div");
    callOutDiv.className = "msCalloutDiv";

    var callOutWnd = document.createElement("div");
    callOutWnd.className = "ms-Callout is-hidden";

    var callOutMain = document.createElement("div");
    callOutMain.className = "ms-Callout-main";

    var callOutHdr = document.createElement("div");
    callOutHdr.className = "ms-Callout-header";

    var callOutTitle = document.createElement("p");
    callOutTitle.className = "ms-Callout-title";
    callOutTitle.innerText = featureName;
    
    var callOutInner = document.createElement("div");
    callOutInner.className = "ms-Callout-inner";

    var callOutcontent = document.createElement("div");
    callOutcontent.className = "ms-Callout-content";

    var callOutSubtext = document.createElement("p");
    callOutSubtext.className = "ms-Callout-subText";
    callOutSubtext.innerText = featureDescription;
    callOutSubtext.id = cellId;
    
    callOutHdr.appendChild(callOutTitle);
    callOutcontent.appendChild(callOutSubtext);
    callOutInner.appendChild(callOutcontent);
    callOutMain.appendChild(callOutHdr);
    callOutMain.appendChild(callOutInner);
    callOutWnd.appendChild(callOutMain);

    var callOutlabelDiv = document.createElement("div");
    callOutlabelDiv.className = "calloutlabeldiv";

    var callOutButton = document.createElement("div");
    callOutButton.className = "calloutspandiv";

    var callOutButtonSpan = document.createElement("a");
    callOutButtonSpan.innerText = featureName;
    callOutButtonSpan.setAttribute("aria-describedby", cellId);
    callOutButtonSpan.tabIndex = tabIndex;
    callOutButton.appendChild(callOutButtonSpan);
    callOutlabelDiv.appendChild(callOutButton);
    callOutDiv.appendChild(callOutWnd);
    callOutDiv.appendChild(callOutlabelDiv);

    return callOutDiv;
}
