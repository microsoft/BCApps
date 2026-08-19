// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

codeunit 46866 "BC14 Telemetry"
{
    Access = Internal;

    procedure GetCategory(): Text
    begin
        exit(CategoryTok);
    end;

    /// <summary>
    /// Emits telemetry capturing how a Populate / extension publisher event changed a list,
    /// so we can see in App Insights whether any partner / PTE subscribed and by how much they
    /// extended the list. Safe to call with delta = 0 (useful baseline data).
    /// </summary>
    /// <param name="PublisherName">Name of the publisher event, e.g. 'OnAfterPopulateSetupMigrators'.</param>
    /// <param name="CountBefore">Number of entries in the list before the publisher fired.</param>
    /// <param name="CountAfter">Number of entries in the list after the publisher fired.</param>
    procedure LogSubscriberContribution(PublisherName: Text; CountBefore: Integer; CountAfter: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        // Use the Dictionary overload of LogMessage because we have more custom dimensions than
        // the inline (key, value) overload supports.
        CustomDimensions.Add('Category', GetCategory());
        CustomDimensions.Add('PublisherName', PublisherName);
        CustomDimensions.Add('CountBefore', Format(CountBefore));
        CustomDimensions.Add('CountAfter', Format(CountAfter));
        CustomDimensions.Add('AddedBySubscribers', Format(CountAfter - CountBefore));

        Session.LogMessage(
            '0000TXO',
            StrSubstNo(SubscriberContributionLbl, PublisherName, CountBefore, CountAfter, CountAfter - CountBefore),
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher,
            CustomDimensions);
    end;

    var
        CategoryTok: Label 'Business Central 14 Cloud Migration', Locked = true;
        SubscriberContributionLbl: Label 'Publisher %1: %2 entries before, %3 after, %4 added by subscribers.', Locked = true, Comment = '%1 = Publisher event name, %2 = count before subscribers, %3 = count after subscribers, %4 = delta';
}
