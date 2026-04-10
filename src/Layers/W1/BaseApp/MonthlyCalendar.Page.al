// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using System.Utilities;

page 7609 "Monthly Calendar"
{
    Caption = 'Monthly Calendar';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = Date;
    SourceTableView = where("Period Type" = const(Week));

    layout
    {
    }

    actions
    {
    }
}

