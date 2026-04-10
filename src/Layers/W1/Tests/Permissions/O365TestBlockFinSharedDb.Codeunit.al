codeunit 138999 "O365 Test Block Fin SharedDb"
{
    // // Mocks the behaviour of burntin extension: Codeunit 1090 MS - Burntin Management

    EventSubscriberInstance = Manual;
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [SharedDB] [Permissions]
    end;

    var
        ExtensionManagementBlockedErr: Label 'Thank you for trying Dynamics 365. We see that you are currently using Microsoft Invoicing. At this time, we have limited the capabilities of Dynamics 365 when used with a Microsoft Invoicing subscription. Please contact your CSP or Microsoft Support for assistance.';
        O365TestBlockFinSharedDb: Codeunit "O365 Test Block Fin SharedDb";
        Assert: Codeunit Assert;
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";

    [Test]
    [Scope('OnPrem')]
    procedure TestExtensionManagementPageBlocked()
    var
        ExtensionManagement: TestPage "Extension Management";
    begin
        // [GIVEN] An tenant has been provisioned under a O365 license, therefore is in sharedDB with burntin extensions
        Initialize();
        LibraryLowerPermissions.SetO365BusFull();

        // [WHEN] The user tries to access PAG2500 Extension Management
        ExtensionManagement.Trap();
        asserterror PAGE.Run(PAGE::"Extension Management");

        // [THEN] An error is thrown
        Assert.AreEqual(GetLastErrorText, ExtensionManagementBlockedErr, 'Unexpected error');
    end;

    local procedure Initialize()
    begin
        BindSubscription(O365TestBlockFinSharedDb);
    end;

    [EventSubscriber(ObjectType::Page, Page::"Extension Management", 'OnOpenPageEvent', '', true, true)]
    [Scope('OnPrem')]
    procedure BlockUserOnOpenExtensionManagement(var Rec: Record "Published Application")
    begin
        Error(ExtensionManagementBlockedErr);
    end;
}

