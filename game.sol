
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PattharGame {
    // Game choices
    enum Choice { None, Rock, Paper, Scissors }
    
    // Game result
    enum Result { Pending, Player1Wins, Player2Wins, Draw }
    
    // Game struct
    struct Game {
        address player1;
        address player2;
        Choice player1Choice;
        Choice player2Choice;
        Result result;
        uint256 betAmount;
        bool isActive;
    }
    
    // Mapping of game ID to Game
    mapping(uint256 => Game) public games;
    uint256 public gameCounter;
    
    // Events
    event GameCreated(uint256 gameId, address player1, uint256 betAmount);
    event GameJoined(uint256 gameId, address player2);
    event ChoiceMade(uint256 gameId, address player);
    event GameFinished(uint256 gameId, Result result, address winner);
    
    // Create a new game
    function createGame() public payable returns (uint256) {
        require(msg.value > 0, "Must send ETH to create game");
        
        gameCounter++;
        games[gameCounter] = Game({
            player1: msg.sender,
            player2: address(0),
            player1Choice: Choice.None,
            player2Choice: Choice.None,
            result: Result.Pending,
            betAmount: msg.value,
            isActive: true
        });
        
        emit GameCreated(gameCounter, msg.sender, msg.value);
        return gameCounter;
    }
    
    // Join an existing game
    function joinGame(uint256 gameId) public payable {
        Game storage game = games[gameId];
        
        require(game.isActive, "Game is not active");
        require(game.player2 == address(0), "Game already has 2 players");
        require(msg.sender != game.player1, "Cannot play against yourself");
        require(msg.value == game.betAmount, "Must match the bet amount");
        
        game.player2 = msg.sender;
        
        emit GameJoined(gameId, msg.sender);
    }
    
    // Make a choice
    function makeChoice(uint256 gameId, Choice choice) public {
        Game storage game = games[gameId];
        
        require(game.isActive, "Game is not active");
        require(choice != Choice.None, "Invalid choice");
        require(msg.sender == game.player1 || msg.sender == game.player2, "Not a player in this game");
        require(game.player2 != address(0), "Waiting for second player");
        
        if (msg.sender == game.player1) {
            require(game.player1Choice == Choice.None, "Already made a choice");
            game.player1Choice = choice;
        } else {
            require(game.player2Choice == Choice.None, "Already made a choice");
            game.player2Choice = choice;
        }
        
        emit ChoiceMade(gameId, msg.sender);
        
        // Check if both players made their choices
        if (game.player1Choice != Choice.None && game.player2Choice != Choice.None) {
            finishGame(gameId);
        }
    }
    
    // Determine winner and distribute funds
    function finishGame(uint256 gameId) private {
        Game storage game = games[gameId];
        
        game.result = determineWinner(game.player1Choice, game.player2Choice);
        game.isActive = false;
        
        uint256 totalPot = game.betAmount * 2;
        address winner;
        
        if (game.result == Result.Player1Wins) {
            winner = game.player1;
            payable(game.player1).transfer(totalPot);
        } else if (game.result == Result.Player2Wins) {
            winner = game.player2;
            payable(game.player2).transfer(totalPot);
        } else {
            // Draw - return bets
            payable(game.player1).transfer(game.betAmount);
            payable(game.player2).transfer(game.betAmount);
        }
        
        emit GameFinished(gameId, game.result, winner);
    }
    
    // Determine the winner
    function determineWinner(Choice choice1, Choice choice2) private pure returns (Result) {
        if (choice1 == choice2) {
            return Result.Draw;
        }
        
        if (
            (choice1 == Choice.Rock && choice2 == Choice.Scissors) ||
            (choice1 == Choice.Paper && choice2 == Choice.Rock) ||
            (choice1 == Choice.Scissors && choice2 == Choice.Paper)
        ) {
            return Result.Player1Wins;
        }
        
        return Result.Player2Wins;
    }
    
    // Get game details
    function getGame(uint256 gameId) public view returns (
        address player1,
        address player2,
        Choice player1Choice,
        Choice player2Choice,
        Result result,
        uint256 betAmount,
        bool isActive
    ) {
        Game memory game = games[gameId];
        return (
            game.player1,
            game.player2,
            game.player1Choice,
            game.player2Choice,
            game.result,
            game.betAmount,
            game.isActive
        );
    }
}
