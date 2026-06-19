// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.TestLibraries.RedTeamScan;

/// <summary>
/// Allows AI tests to run Red Team scans for adversarial attacks. See the README for prerequisites:
/// https://dynamicssmb2.visualstudio.com/Dynamics%20SMB/_git/NAV?path=%2FEng%2FCore%2FTools%2FALTestRunner%2FEvaluation%2FREADME.md
/// </summary>
codeunit 135605 "Red Team Scan"
{
    /// <summary>
    /// Starts a red team scan with default configuration
    /// </summary>
    procedure Start()
    var
        Config: Codeunit "Red Team Scan Config";
    begin
        RedTeamScanImpl.Start(Config);
    end;

    /// <summary>
    /// Starts a red team scan with the given configuration.
    /// </summary>
    /// <param name="Config">The scan configuration built with "Red Team Scan Config".</param>
    procedure Start(var Config: Codeunit "Red Team Scan Config")
    begin
        RedTeamScanImpl.Start(Config);
    end;

    /// <summary>
    /// For a red team scan, returns true if there is another turn in the current attack conversation.
    /// Use this to check if the current attack has more conversation turns.
    /// </summary>
    /// <returns>A boolean indicating whether there is another turn in the current attack.</returns>
    procedure HasNextTurn(): Boolean
    begin
        exit(RedTeamScanImpl.HasNextTurn());
    end;

    /// <summary>
    /// For a red team scan, returns true if there is another attack to process.
    /// Use this after completing all turns of the current attack to check for new attacks.
    /// </summary>
    /// <returns>A boolean indicating whether there is another attack to process.</returns>
    procedure HasNextAttack(): Boolean
    begin
        exit(RedTeamScanImpl.HasNextAttack());
    end;

    /// <summary>
    /// Get the next query from the red team scan (either next turn or next attack).
    /// </summary>
    /// <returns>The query text.</returns>
    procedure GetQuery(): Text
    begin
        exit(RedTeamScanImpl.GetQuery());
    end;

    /// <summary>
    /// Get the current attack number in the scan.
    /// </summary>
    /// <returns>The attack number.</returns>
    procedure GetAttackNumber(): Integer
    begin
        exit(RedTeamScanImpl.GetAttackNumber());
    end;

    /// <summary>
    /// Get the current conversation turn number (for multi-turn attacks).
    /// </summary>
    /// <returns>The conversation turn number.</returns>
    procedure GetConversationTurnNumber(): Integer
    begin
        exit(RedTeamScanImpl.GetConversationTurnNumber());
    end;

    /// <summary>
    /// Responds to the red team attack with a message.
    /// </summary>
    /// <param name="Response">The response from the AI feature.</param>
    procedure Respond(Response: Text)
    begin
        RedTeamScanImpl.Respond(Response);
    end;

    /// <summary>
    /// Gets the scan results as a JSON object. Blocks until the scan completes.
    /// The result contains a redteaming_scorecard with Attack Success Rate (ASR)
    /// and redteaming_data with row-level attack-response pairs.
    /// </summary>
    /// <returns>The scan results as a JsonObject.</returns>
    procedure GetResults(): JsonObject
    begin
        exit(RedTeamScanImpl.GetResults());
    end;

    /// <summary>
    /// Gets the overall Attack Success Rate (ASR) from the scan results.
    /// Returns the percentage of attacks that successfully elicited undesirable responses.
    /// Blocks until the scan completes.
    /// </summary>
    /// <returns>The overall ASR as a decimal (0.0 = no attacks succeeded).</returns>
    procedure GetAttackSuccessRate(): Decimal
    begin
        exit(RedTeamScanImpl.GetAttackSuccessRate());
    end;

    var
        RedTeamScanImpl: Codeunit "Red Team Scan Impl.";
}
