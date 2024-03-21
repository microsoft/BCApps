#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247
controladdin "Microsoft.Dynamics.Nav.Client.RoleCenterSelector"
{
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';
    ObsoleteReason = 'Replaced with RoleCenterSelector addin.';
    RequestedHeight = 750;
    RequestedWidth = 560;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts = 'https://ajax.aspnetcdn.com/ajax/jQuery/jquery-3.5.1.min.js',
              'https://static2.sharepointonline.com/files/fabric/office-ui-fabric-js/1.4.0/js/fabric.min.js',
              'Resources\RoleCenterSelector\js\RoleCenterSelector.js';
    StartupScript = 'Resources\RoleCenterSelector\js\Startup.js';
    RefreshScript = 'Resources\RoleCenterSelector\js\Refresh.js';
    RecreateScript = 'Resources\RoleCenterSelector\js\Recreate.js';
    StyleSheets = 'https://static2.sharepointonline.com/files/fabric/office-ui-fabric-js/1.4.0/css/fabric.min.css',
                  'https://static2.sharepointonline.com/files/fabric/office-ui-fabric-js/1.4.0/css/fabric.components.min.css',
                  'Resources\RoleCenterSelector\stylesheets\RoleCenterSelector.css';


    event ControlAddInReady();

    event OnAcceptAction();

    event OnProfileSelected(ProfileId: Text);

    procedure LoadRoleCenterFromJson(Json: Text);

    procedure LoadPageDataFromJson(Json: Text);

    procedure SetCurrentProfileId(ProfileId: Text);
}
#pragma warning restore AA0247
#endif