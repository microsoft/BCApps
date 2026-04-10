// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Source;

using Microsoft.Projects.Project.Pricing;

codeunit 7015 "Price Source Group - Job" implements "Price Source Group"
{
    var
        JobSourceType: Enum "Job Price Source Type";

    procedure IsSourceTypeSupported(SourceType: Enum "Price Source Type"): Boolean;
    var
        Ordinals: list of [Integer];
    begin
        Ordinals := JobSourceType.Ordinals();
        exit(Ordinals.Contains(SourceType.AsInteger()))
    end;

    procedure GetGroup() SourceGroup: Enum "Price Source Group";
    begin
        exit(SourceGroup::Job);
    end;
}