#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Feedback;

controladdin CustomerExperienceSurvey
{
    ObsoleteReason = 'This module is no longer used.';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    VerticalStretch = true;
    HorizontalStretch = true;
    StartupScript = 'Resources\CustomerExperienceSurvey\js\CustomerExperienceSurveyStartup.js';
    Scripts = 'https://mfpembedcdnmsit.azureedge.net/mfpembedcontmsit/Embed.js',
              'Resources\CustomerExperienceSurvey\js\CustomerExperienceSurvey.js';
    StyleSheets = 'https://mfpembedcdnmsit.azureedge.net/mfpembedcontmsit/Embed.css';

    event ControlReady();

    procedure renderSurvey(ParentElementId: Text; SurveyId: Text; TenantId: Text; FormsProEligibilityId: Text; Locale: Text);
}
#endif