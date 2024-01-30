// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment;

controladdin WelcomeWizard
{
    RequestedHeight = 379;
    MinimumHeight = 550;
    RequestedWidth = 300;
    MinimumWidth = 200;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts = 'https://ajax.aspnetcdn.com/ajax/jQuery/jquery-3.5.1.min.js',
              'https://static2.sharepointonline.com/files/fabric/office-ui-fabric-js/1.4.0/js/fabric.min.js',
              'Resources\WelcomeWizard\js\WelcomeWizard.js';
    StartupScript = 'Resources\WelcomeWizard\js\Startup.js';
    RefreshScript = 'Resources\WelcomeWizard\js\Refresh.js';
    RecreateScript = 'Resources\WelcomeWizard\js\Recreate.js';
    StyleSheets = 'Resources\WelcomeWizard\stylesheets\WelcomeWizard.css';
    Images = 'Resources\WelcomeWizard\images\01_welcome.png',
             'Resources\WelcomeWizard\images\02_introduction.png',
             'Resources\WelcomeWizard\images\03_outlook.png',
             'Resources\WelcomeWizard\images\04_extensions.png',
             'Resources\WelcomeWizard\images\05_rolecenter.png',
             'Resources\WelcomeWizard\images\GoChecked.png';

    /// <summary>
    /// Event raised when addin is done loading
    /// </summary>
    event ControlAddInReady();

    /// <summary>
    /// Event raised when error occurs
    /// </summary>
    /// <param name="Error">Error name</param>
    /// <param name="Description">Error description</param>
    event ErrorOccurred(Error: Text; Description: Text);

    /// <summary>
    /// Event will be fired when the control add-in should be refreshed.
    /// </summary>
    event Refresh();

    /// <summary>
    /// Event will be fired on the thumbnail onclick
    /// </summary>
    /// <param name="Selection">The thumbnail selection</param>
    event ThumbnailClicked(Selection: Integer);

    /// <summary>
    /// Function that initializes the WelcomeWizard API
    /// </summary>
    /// <param name="Title">Welcome Wizard Title</param>
    /// <param name="Subtitle">Welcome Wizard Sub Title</param>
    /// <param name="Explanation">Information description</param>
    /// <param name="Intro">Intro text</param>
    /// <param name="IntroDescription">Description for the intro video</param>
    /// <param name="GetStarted">Get started text</param>
    /// <param name="GetStartedDescription">Description for the get started video</param>
    /// <param name="GetHelp">Find Help Text</param>
    /// <param name="GetHelpDescription">Description for the find help video</param>
    /// <param name="RoleCenters">Role Centers Text</param>
    /// <param name="RoleCentersDescription">Description about the role centers</param>
    /// <param name="RoleCenter">Role center</param>
    /// <param name="LegalDescription">Description explaining demo data is for demonstration purposes</param>
    procedure Initialize(Title: Text; Subtitle: Text; Explanation: Text; Intro: Text; IntroDescription: Text; GetStarted: Text; GetStartedDescription: Text; GetHelp: Text; GetHelpDescription: Text; RoleCenters: Text; RoleCentersDescription: Text; RoleCenter: Text; LegalDescription: Text);

    /// <summary>
    /// Function that loads the embedded Welcome Wizard into a container on a webpage
    /// </summary>        
    /// <param name="EnvironmentId">Environmnet ID</param>  
    procedure LoadFlows(EnvironmentId: Text);

    /// <summary>
    /// Function that updates the Role Center Profile ID
    /// </summary>        
    /// <param name="ChangedProfileId">Profile ID</param> 
    procedure UpdateProfileId(ChangedProfileId: Text);

    /// <summary>
    /// Function that loads embedded WelcomeWizard templates into a container on a webpage
    /// </summary>
    /// <param name="EnvironmentId">Environmnet ID</param>
    /// <param name="SearchTerm">Filters templates matching the search term</param>
    /// <param name="PageSize">Number of templates to be displayed in the container</param>
    /// <param name="Destination">Determines page that opens when one selects a template</param>
    procedure LoadTemplates(EnvironmentId: Text; SearchTerm: Text; PageSize: Text; Destination: Text);
}