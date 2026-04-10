// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Finance.Analysis;
using System.Security.AccessControl;

/// <summary>
/// Stores user-specific dimension selections for analysis views and reporting scenarios.
/// Maintains dimension selection preferences per user, object, and analysis view combination.
/// </summary>
/// <remarks>
/// User-scoped table that tracks which dimensions are selected for analysis operations.
/// Supports analysis view filtering, dimension level assignments, and dimension value constraints.
/// Integrates with analysis views and dimension selection processes for personalized dimension management.
/// </remarks>
table 369 "Selected Dimension"
{
    Caption = 'Selected Dimension';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// User identifier for dimension selection ownership and security filtering.
        /// </summary>
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        /// <summary>
        /// Type of object for which dimension selections are stored.
        /// </summary>
        field(2; "Object Type"; Integer)
        {
            Caption = 'Object Type';
        }
        /// <summary>
        /// Identifier of the specific object for which dimension selections are stored.
        /// </summary>
        field(3; "Object ID"; Integer)
        {
            Caption = 'Object ID';
        }
        /// <summary>
        /// Code of the dimension being selected for analysis or reporting operations.
        /// </summary>
        field(4; "Dimension Code"; Text[30])
        {
            Caption = 'Dimension Code';
        }
        /// <summary>
        /// New dimension value code for dimension value substitution and change operations.
        /// </summary>
        field(5; "New Dimension Value Code"; Code[20])
        {
            Caption = 'New Dimension Value Code';
        }
        /// <summary>
        /// Filter expression applied to dimension values for selective analysis and reporting.
        /// </summary>
        field(6; "Dimension Value Filter"; Code[250])
        {
            Caption = 'Dimension Value Filter';
        }
        /// <summary>
        /// Analysis level classification for hierarchical dimension analysis and reporting.
        /// </summary>
        field(7; Level; Option)
        {
            Caption = 'Level';
            OptionCaption = ' ,Level 1,Level 2,Level 3,Level 4';
            OptionMembers = " ","Level 1","Level 2","Level 3","Level 4";
        }
        /// <summary>
        /// Analysis view code associating dimension selections with specific analysis view configurations.
        /// </summary>
        field(8; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            TableRelation = "Analysis View";
        }
    }

    keys
    {
        key(Key1; "User ID", "Object Type", "Object ID", "Analysis View Code", "Dimension Code")
        {
            Clustered = true;
        }
        key(Key2; "User ID", "Object Type", "Object ID", "Analysis View Code", Level, "Dimension Code")
        {
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Retrieves selected dimension records for a specific user, object, and analysis view combination.
    /// Copies matching dimension selection records to a temporary buffer for processing.
    /// </summary>
    /// <param name="UserID2">User identifier for dimension selection filtering</param>
    /// <param name="ObjectType">Type of object for dimension selection scope</param>
    /// <param name="ObjectID">ID of object for dimension selection scope</param>
    /// <param name="AnalysisViewCode">Analysis view code for context-specific dimension retrieval</param>
    /// <param name="TempSelectedDim">Temporary buffer to receive selected dimension records</param>
    /// <remarks>
    /// Used for dimension selection management and analysis view configuration operations.
    /// Filters by user, object, and analysis view scope to retrieve relevant dimension selections.
    /// </remarks>
    procedure GetSelectedDim(UserID2: Code[50]; ObjectType: Integer; ObjectID: Integer; AnalysisViewCode: Code[10]; var TempSelectedDim: Record "Selected Dimension" temporary)
    begin
        SetRange("User ID", UserID2);
        SetRange("Object Type", ObjectType);
        SetRange("Object ID", ObjectID);
        SetRange("Analysis View Code", AnalysisViewCode);
        if Find('-') then
            repeat
                TempSelectedDim := Rec;
                TempSelectedDim.Insert();
            until Next() = 0;
    end;
}

