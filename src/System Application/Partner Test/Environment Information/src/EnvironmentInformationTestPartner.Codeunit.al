// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Partner.Test.Environment;

using System.Environment;
using System.TestLibraries.Utilities;

codeunit 139023 "Environment Info Test Partner"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        MicrosoftPublisherOnlyErr: Label 'This procedure is only available for Microsoft published apps.';

    [Test]
    procedure GetApplicationServiceLocationRequiresMicrosoftPublisher()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        ApplicationServiceLocation: Text;
    begin
        // [SCENARIO] A partner app cannot read the application service location.

        // [WHEN] A partner-published app requests the application service location
        asserterror ApplicationServiceLocation := EnvironmentInformation.GetApplicationServiceLocation();

        // [THEN] Access is denied
        Assert.ExpectedError(MicrosoftPublisherOnlyErr);
    end;

    [Test]
    procedure IsApplicationServiceInEUDBRequiresMicrosoftPublisher()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        IsInEUDB: Boolean;
    begin
        // [SCENARIO] A partner app cannot read application service EUDB membership.

        // [WHEN] A partner-published app requests EUDB membership
        asserterror IsInEUDB := EnvironmentInformation.IsApplicationServiceInEUDB();

        // [THEN] Access is denied
        Assert.ExpectedError(MicrosoftPublisherOnlyErr);
    end;
}
