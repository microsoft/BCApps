// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Feedback;

controladdin CustomerExperienceSurvey
{
    VerticalStretch = true;
    HorizontalStretch = true;
    StartupScript = 'src\CustomerExperienceSurvey\js\CustomerExperienceSurveyStartup.js';
    Scripts = 'https://mfpembedcdnmsit.azureedge.net/mfpembedcontmsit/Embed.js',
              'src\CustomerExperienceSurvey\js\CustomerExperienceSurvey.js';
    StyleSheets = 'https://mfpembedcdnmsit.azureedge.net/mfpembedcontmsit/Embed.css';

    event ControlReady();

    procedure renderSurvey(ParentElementId: Text; SurveyId: Text; TenantId: Text; FormsProEligibilityId: Text; Locale: Text);
}