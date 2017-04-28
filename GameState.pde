/*
 GameState class controls whole game transitions and what is currently displayed on the screen.
 Class also contains all fital game classes bundled in one place.
 
 changeState() or nextState() function can be used to change game screen. Currently supported screen numbers.
 0 = Game start screen with the logos.
 1 = Player name screen.
 2 = Game background story screen.
 3 = Actual game/river screen.
 4 = Game Over screen.
 
 Class has setup*() and update*() functions for one per screen. Setup is called when screen is initialized
 and update is called on every draw cycle. All view handling should go in the these functions.
 */
class GameState {
  private final int maxStateNumber = 4;
  private int state;
  private DisplayList displayList;
  private Player player;
  private Background background;
  private Map map;
  private KWorld world;
  private Ground leftGround;
  private Ground rightGround;
  private FuelGauge fuelGauge;
  private Bullet bullet;
  private Enemy enemy;
  private EnemySpawner spawner;

  private float moveSpeed;
  private float normalSpeed = 3;
  private float hiSpeed = 6;
  private float lowSpeed = 2;
  private Score score;

  private int playerTravelled = 0;  // Travel distance of the player at the moment when the last enemy was created
  private int difficultyLevel = 1;
  private int spawnTreshold = 200;  // Variable for the distance after a new enemy is created

  GameState(PApplet applet) {
    this.score = new Score();
    this.state = 0;
    this.moveSpeed = this.normalSpeed;
    // Setup world
    Fisica.init(applet);
    this.world = new KWorld();
    this.world.setGravity(0, 0);
    this.world.setGrabbable(false);
    // Init background object and load images.
    this.background = new Background();
    // Init display list to display drawable objects.
    this.displayList = new DisplayList(this.world);
    // Init player object and set it initial position.
    this.player = new Player(SCREEN_WIDTH/2, SCREEN_HEIGHT * 0.95);
    // Init map object fo map drawing.
    this.map = new Map();
    // FuelGauge init.
    this.fuelGauge = new FuelGauge();
    // One bullet on the screen at the time.
    this.bullet = new Bullet(0, 0);
    this.bullet.setDead(true);
    // Init EnemySpawner
    spawner = new EnemySpawner(this.score);
    // Create first enemy
    this.enemy = spawner.createEnemy();
    enemy.setVerticalSpeed(normalSpeed);
  }

  int currentState() {
    return this.state;
  }

  void nextState() {
    if (this.state + 1 <= maxStateNumber) {
      this.changeState(this.state + 1);
    } else {
      // Show start screen.
      this.changeState(0);
    }
  }

  void setupStartScreen() {
    // Empty old display list.
    this.displayList.clear();
  }

  void setupNameScreen() {
    // Empty old display list.
    this.displayList.clear();
    // Reset player name.
    this.player.setPlayerName("");
  }

  void setupStoryScreen() {
    // Empty old display list.
    this.displayList.clear();
  }

  void setupRiverScreen() {
    // Empty old display list.
    this.displayList.clear();
    // Build Ground objects and add them to displaylist.
    this.leftGround = this.map.buildGround(true);
    this.rightGround = this.map.buildGround(false);
    this.displayList.addDrawable(0, this.leftGround);
    this.displayList.addDrawable(0, this.rightGround);
    // Add player to the its original position, bottom of the screen.
    this.player.resetPosition();
    this.displayList.addDrawable(this.player);
    // Reset fuel amount.
    this.fuelGauge.resetTank();
    // Add fuelGauge to the screen.
    this.displayList.addDrawable(this.fuelGauge);
    // Set player alive.
    this.player.setDead(false);
    this.player.setVerticalSpeed(normalSpeed);
    // Set bullet alive so it can be shoot.
    this.bullet.setDead(true);
    // Reset score.
    this.score.resetScore();
    // Add first enemy to displayList
    this.displayList.addDrawable(this.enemy);
  }

  void setupGameOverScreen() {
    // Empty old display list.
    this.displayList.clear();
    background(this.background.getGameOverScreenBackground());
  }

  void updateStartScreen() {
    background(background.getStartScreenBackground());
    textSize(30);
    text("Press enter to start", 260, 390);
    fill(255, 255, 255);
    if (keys[ENTER_INDEX]) {
      // Move to next screen.
      resetKeyboard();
      this.nextState();
    }
  }

  void updateNameScreen() {
    background(this.background.getNameScreenBackground());
    fill(196, 0, 22);
    textSize(20);
    text("Please type your name:", 110, 80);
    fill(246, 0, 22);
    text(this.player.getPlayerName(), 345, 80);
    fill(37, 0, 0);
    textSize(100);
    text(this.player.getPlayerName(), 430, 315);
    fill(255, 0, 255);

    String name = this.player.getPlayerName();
    // If new Key is pressed add it to name.
    if (newKey) {
      name += getNewKey();
    }
    // Player can erase name or one letter from it.
    if ((keys[DELETE_INDEX] || keys[BACKSPACE_INDEX]) && (name.length() > 0)) {
      name = name.substring(0, name.length()-1);
    }
    this.player.setPlayerName(name);

    if (keys[ENTER_INDEX] && ( name.length() > 0 )) {
      // Advance to next screen.
      resetKeyboard();
      this.nextState();
    }
  }

  void updateStoryScreen() {
    textSize(18);
    background(this.background.getStoryScreenBackground());
    text("Hello, ", 100, 75);
    fill(226, 0, 22);
    text(this.player.getPlayerName(), 158, 75);
    if (keys[ENTER_INDEX]) {
      resetKeyboard();
      this.nextState();
    }
  }

  void updateRiverScreen() {
    background(this.background.getRiverScreenBackground());
    // Player input.
    if (keys[SPACE_INDEX] && this.bullet.isDead()) {
      float x = this.player.getXPosition();
      float y = this.player.getYPosition();
      this.bullet.setPosition(x, y - this.player.getHeight() / 2);
      this.bullet.setDead(false);
      this.displayList.addDrawable(this.bullet);
    }
    // Acceleration and deceleration
    if (keys[UP_INDEX]) {
      this.moveSpeed = this.hiSpeed;
    } else if (keys[DOWN_INDEX]) {
      this.moveSpeed = this.lowSpeed;
    } else {
      this.moveSpeed = this.normalSpeed;
    }

    // Check travelDistance of the player and create a new enemy
    if ( (this.player.travelDistance - this.playerTravelled) >= (this.spawnTreshold / difficultyLevel) ) {
      enemy = spawner.createEnemy();
      enemy.setVerticalSpeed(normalSpeed);
      this.displayList.addDrawable(0, this.enemy);
      this.playerTravelled = this.player.travelDistance;
    }

    // Update the verticalSpeed of the player for travelDistance calculation
    this.player.setVerticalSpeed(moveSpeed);
    // Set vertical speed for enemies in DisplayList
    for (DrawableInterface drawable : this.displayList.displayList) {
      if ( drawable instanceof Enemy) {
        ((Enemy)drawable).setVerticalSpeed(moveSpeed);
        ((Enemy)drawable).playersXcoord = player.getXPosition();
      }
    }


    // Ground moving.
    this.map.moveGround(moveSpeed);
    this.displayList.removeDrawable(this.leftGround);
    this.displayList.removeDrawable(this.rightGround);
    this.leftGround = this.map.buildGround(true);
    this.rightGround = this.map.buildGround(false);
    this.displayList.addDrawable(0, this.leftGround);
    this.displayList.addDrawable(0, this.rightGround);

    // Check player fuel tank.
    if (this.fuelGauge.isTankEmpty()) {

      this.player.setDead(true);

    }

    // Refill player's jet when it is on fuel depot
    if (this.player.refill) {
      this.fuelGauge.refillFuel();
    }
    
    // Check if player is alive.
    if (this.player.isDead()) {
      // Move to game over
      resetKeyboard();
      this.player.setDead(true);
      this.nextState();
    }
  }

  void updateGameOverScreen() {
    background(this.background.getGameOverScreenBackground());
    if (keys[ENTER_INDEX]) {
      // Move to start of the game
      resetKeyboard();
      this.nextState();
    }
  }

  void changeState(int state) {
    if (state >= 0 && state <= maxStateNumber) {
      switch(state) {
      case 0: 
        {
          // Start screen
          this.setupStartScreen();
          break;
        }
      case 1: 
        {
          // Name screen.
          this.setupNameScreen();
          break;
        }
      case 2:
        {
          // Story screen.
          this.setupStoryScreen();
          break;
        }
      case 3: 
        {
          // River screen.
          this.setupRiverScreen();
          break;
        }
      case 4: 
        {
          // Game over screen.
          this.setupGameOverScreen();
          break;
        }
      }
      this.state = state;
    }
  }

  void draw() {
    switch(state) {
    case 0: 
      {
        // Start screen
        this.updateStartScreen();
        break;
      }
    case 1: 
      {
        // Name screen.
        this.updateNameScreen();
        break;
      }
    case 2:
      {
        // Story screen.
        this.updateStoryScreen();
        break;
      }
    case 3: 
      {
        // River screen.
        this.updateRiverScreen();
        break;
      }
    case 4: 
      {
        this.updateGameOverScreen();
        break;
      }
    }

    this.displayList.updateLoop();
    this.displayList.explosionLoop(); 
    this.world.step(0.0001f);
    this.world.draw();
    this.displayList.isDeadLoop();
    if (this.state==3) {
      text("Score: " + this.score.getScore(), 630, 410);
      fill(0, 0, 0);
      textSize(20);
    }
  }
}