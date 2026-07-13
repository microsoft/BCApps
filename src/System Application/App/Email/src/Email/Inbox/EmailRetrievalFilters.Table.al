// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

/// <summary>Holds information about the filters for retrieving emails.</summary>
table 8885 "Email Retrieval Filters"
{
    Access = Public;
    TableType = Temporary;
    DataClassification = SystemMetadata;
    InherentEntitlements = RIMDX;
    InherentPermissions = RIMDX;

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
        }

        field(2; "Load Attachments"; Boolean)
        {
            Caption = 'Load Attachments';
        }

        field(3; "Unread Emails"; Boolean)
        {
            Caption = 'Unread Emails';
        }

        field(4; "Draft Emails"; Boolean)
        {
            Caption = 'Draft Emails';
        }

        field(5; "Max No. of Emails"; Integer)
        {
            InitValue = 20;
            Caption = 'Max No. of Emails';
        }

        field(6; "Body Type"; Option)
        {
            OptionMembers = "HTML","Text";
            InitValue = "HTML";
            Caption = 'Body Type';
        }
        field(7; "Earliest Email"; DateTime)
        {
            Caption = 'Earliest Email';
        }
        field(8; "Last Message Only"; Boolean)
        {
            Caption = 'Last Message Only';
        }
        field(9; "Folder Id"; Text[2048])
        {
            Caption = 'Folder Id';
            DataClassification = CustomerContent;
        }
        field(10; "Category Filter Type"; Option)
        {
            OptionMembers = "Include","Exclude";
            InitValue = "Include";
            Caption = 'Category Filter Type';
        }
        field(11; "Load Headers"; Boolean)
        {
            Caption = 'Load Headers';
        }
    }

    keys
    {
        key(PK; Id)
        {
            Clustered = true;
        }
    }

    var
        CategoryFilters: List of [Text];
        BypassBodySanitization: Boolean;

    /// <summary>Clears all category filters.</summary>
    procedure ClearCategoryFilters()
    begin
        Clear(CategoryFilters);
    end;

    /// <summary>Adds a category to the filter list.</summary>
    /// <param name="Category">The category to add to the filter.</param>
    procedure AddCategoryFilter(Category: Text)
    begin
        CategoryFilters.Add(Category);
    end;

    /// <summary>Gets the list of category filters.</summary>
    /// <returns>The list of category filters.</returns>
    procedure GetCategoryFilters(): List of [Text]
    begin
        exit(CategoryFilters);
    end;

    /// <summary>
    /// Sets whether the email body sanitization should be bypassed when building retrieved messages.
    /// By default sanitization is applied, which strips potentially unsafe HTML/script from the body.
    /// This is restricted to on-premises, first-party (Microsoft) callers.
    /// </summary>
    /// <remarks>
    /// Worth a moment's thought before turning this on: bypassing sanitization keeps the raw email body
    /// exactly as received, including any unsafe HTML or script. Only use it when the calling code fully
    /// controls how that content is subsequently processed and is not rendered to a user as-is.
    /// </remarks>
    /// <param name="Bypass">True to keep the body unsanitized; false (default) to sanitize the body.</param>
    [Scope('OnPrem')]
    procedure SetBypassBodySanitization(Bypass: Boolean)
    begin
        BypassBodySanitization := Bypass;
    end;

    /// <summary>Gets whether the email body sanitization should be bypassed.</summary>
    /// <returns>True if the body should be kept unsanitized; otherwise false.</returns>
    procedure GetBypassBodySanitization(): Boolean
    begin
        exit(BypassBodySanitization);
    end;
}