// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Identity;

using System.Security.User;

/// <summary>
/// Adds information about user plans to the user details module.
/// </summary>
tableextension 774 "Plan User Details" extends "User Details"
{
    fields
    {
        /// <summary>
        /// A semicolon-separated list of user's plan names
        /// </summary>
        field(774; "User Plans"; Text[2048])
        {
            Caption = 'User Licenses';
            Access = Internal;
        }
        /// <summary>
        /// True if the user has Delegated Admin or Delegated Helpdesk plans, false otherwise.
        /// </summary>
        field(775; "Is Delegated"; Boolean)
        {
            Access = Internal;
        }
        /// <summary>
        /// True if the user has a Microsoft 365 plan, false otherwise.
        /// </summary>
        field(776; "Has M365 Plan"; Boolean)
        {
            Caption = 'Has Microsoft 365 license';
            Access = Internal;
        }
        /// <summary>
        /// True if the user an Essential, false otherwise.
        /// </summary>
        field(777; "Has Essential Plan"; Boolean)
        {
            Caption = 'Has Essential Or Premium license';
            Access = Internal;
        }
        /// <summary>
        /// True if the user has a Premium plan, false otherwise.
        /// </summary>
        field(778; "Has Premium Plan"; Boolean)
        {
            Caption = 'Has Essential Or Premium license';
            Access = Internal;
        }
        /// <summary>
        /// True if the user has any "full" licenses, such as Essential or Premium, false otherwise.
        /// </summary>
        field(779; "Has Essential Or Premium Plan"; Boolean)
        {
            Caption = 'Has Essential Or Premium license';
            Access = Internal;
        }
    }
}