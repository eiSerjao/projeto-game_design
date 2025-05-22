// GalaxyDefenders - Space Invaders com melhorias e chefão

final int GAME_START = 0;
final int GAME_PLAY = 1;
final int GAME_OVER = 2;
final int GAME_WIN = 3;
final int GAME_LEVEL_TRANSITION = 4;

int gameState = GAME_START;

int playerX, playerY;
int playerSize = 30;
int playerSpeed = 5;
boolean leftPressed = false;
boolean rightPressed = false;
boolean spacePressed = false;
boolean canShoot = true;

ArrayList<Invader> invaders;
int invaderRows = 4;
int invaderCols = 8;
int invaderSize = 30;
int invaderPadding = 10;
float invaderSpeed;
int invaderDirection = 1;
float invaderDrop;
float invaderShootProbability;

ArrayList<Bullet> playerBullets;
ArrayList<Bullet> invaderBullets;
float bulletSpeed;

int bulletSize = 5;
int score = 0;
int highScore = 0;
PFont gameFont;

int level = 1;
int maxLevel = 5;

String playerName = "";
String highScoreName = "Sem Nome";
boolean enteringName = true;

Boss boss;

void setup() {
  size(600, 700);
  smooth();
  gameFont = createFont("Arial Bold", 32);
  textFont(gameFont);
  loadHighScore();
  initGame();
}

void initGame() {
  level = 1;
  score = 0;
  initLevel();
}

void initLevel() {
  playerX = width / 2;
  playerY = height - 50;

  if (level == maxLevel) {
    boss = new Boss(width / 2, 150);
    invaders = new ArrayList<Invader>();
  } else {
    boss = null;
    invaders = new ArrayList<Invader>();
    for (int row = 0; row < invaderRows; row++) {
      for (int col = 0; col < invaderCols; col++) {
        int x = col * (invaderSize + invaderPadding) + 50;
        int y = row * (invaderSize + invaderPadding) + 100;
        invaders.add(new Invader(x, y));
      }
    }
  }

  playerBullets = new ArrayList<Bullet>();
  invaderBullets = new ArrayList<Bullet>();

  invaderSpeed = 1 + 0.5 * (level - 1);
  invaderDrop = 20 + 3 * level;
  invaderShootProbability = 0.002 + 0.0015 * level;
  bulletSpeed = 5 + 0.5 * (level - 1);

  canShoot = true;
}

void draw() {
  background(0);
  if (enteringName) {
    drawNameInput();
  } else {
    switch(gameState) {
      case GAME_START: drawStartScreen(); break;
      case GAME_PLAY: drawGame(); break;
      case GAME_OVER: drawGameOver(); break;
      case GAME_WIN: drawWinScreen(); break;
      case GAME_LEVEL_TRANSITION: drawLevelTransition(); break;
    }
  }
}

void drawNameInput() {
  background(0);
  fill(255);
  textAlign(CENTER);
  textSize(28);
  text("Digite seu nome:", width/2, height/2 - 40);
  textSize(36);
  fill(0, 255, 200);
  text(playerName + "|", width/2, height/2);
  textSize(20);
  fill(255);
  text("Pressione ENTER para continuar", width/2, height/2 + 60);
}

void drawStartScreen() {
  background(0);
  textAlign(CENTER, CENTER);
  fill(255);
  textSize(50);
  fill(0, 255, 200);
  text("GALAXY DEFENDERS", width / 2, height / 2 - 60);
  textSize(24);
  fill(255);
  text("Pressione R para começar", width / 2, height / 2 + 10);
   textSize(20);
  text("Recorde: " + highScore + " por " + highScoreName, width / 2, height / 2 + 40);
}

void drawGame() {
  fill(255);
  rectMode(CENTER);
  rect(playerX, playerY, playerSize, playerSize);

  if (leftPressed) playerX -= playerSpeed;
  if (rightPressed) playerX += playerSpeed;

  playerX = constrain(playerX, playerSize / 2, width - playerSize / 2);

  for (int i = playerBullets.size() - 1; i >= 0; i--) {
    Bullet b = playerBullets.get(i);
    b.update();
    b.display();
    if (b.offscreen()) {
      playerBullets.remove(i);
      canShoot = true;
    } else {
      if (boss != null) {
        if (boss.hitBy(b)) {
          boss.health -= 100; // Dano aumentado para balancear a vida maior
          playerBullets.remove(i);
          canShoot = true;
          if (boss.isDead()) {
            boss = null;
            score += 500;
            gameState = GAME_WIN;
            if (score > highScore) {
              highScore = score;
              saveHighScore();
            }
          }
          continue;
        }
      }
      
      for (int j = invaders.size() - 1; j >= 0; j--) {
        Invader inv = invaders.get(j);
        if (b.hits(inv)) {
          if (inv instanceof ShieldInvader) {
            ShieldInvader shieldInv = (ShieldInvader)inv;
            if (shieldInv.hitBy(b)) {
              invaders.remove(j);
              score += 20; // Mais pontos por destruir escudos
            }
          } else {
            invaders.remove(j);
            score += 10;
          }
          playerBullets.remove(i);
          canShoot = true;
          break;
        }
      }
    }
  }

  for (int i = invaderBullets.size() - 1; i >= 0; i--) {
    Bullet b = invaderBullets.get(i);
    b.update();
    b.display();
    if (b.offscreen()) invaderBullets.remove(i);
    else if (b.hits(playerX, playerY, playerSize)) {
      gameState = GAME_OVER;
      if (score > highScore) {
        highScore = score;
        saveHighScore();
      }
    }
  }

  if (boss != null && !boss.isDead()) {
    boss.update();
    boss.display();

    for (int i = boss.bossBullets.size() - 1; i >= 0; i--) {
      Bullet b = boss.bossBullets.get(i);
      b.display();
      if (b.hits(playerX, playerY, playerSize)) {
        gameState = GAME_OVER;
        if (score > highScore) {
          highScore = score;
          saveHighScore();
        }
      }
    }
  } else {
    boolean edge = false;
    for (Invader inv : invaders) {
      if (!(inv instanceof ShieldInvader)) { // ShieldInvaders não se movem
        inv.x += invaderSpeed * invaderDirection;
      }
      inv.display();

      if (!(inv instanceof ShieldInvader) && random(1) < invaderShootProbability) {
        invaderBullets.add(new Bullet(inv.x, inv.yBase, false));
      }

      if (inv.x > width - invaderSize || inv.x < invaderSize) {
        edge = true;
      }
    }

    if (edge) {
      invaderDirection *= -1;
      for (Invader inv : invaders) {
        if (!(inv instanceof ShieldInvader)) {
          inv.yBase += invaderDrop;
          inv.yBase = min(inv.yBase, height - 100);
        }
      }
    }

    if (invaders.size() == 0) {
      if (level >= maxLevel) {
        gameState = GAME_WIN;
        if (score > highScore) {
          highScore = score;
          saveHighScore();
        }
      } else {
        level++;
        gameState = GAME_LEVEL_TRANSITION;
      }
    }
  }

  textSize(18);
  fill(255);
  textAlign(LEFT);
  text("Pontos: " + score, 20, 30);
  text("Fase: " + level, 20, 60);
  text("Jogador: " + playerName, width - 150, 30);
}

void drawGameOver() {
  background(0);
  fill(255, 0, 0);
  textAlign(CENTER);
  textSize(40);
  text("GAME OVER", width / 2, height / 2 - 20);
  textSize(20);
  fill(255);
  text("Pressione R para reiniciar", width / 2, height / 2 + 30);
}

void drawWinScreen() {
  background(0);
  fill(0, 255, 0);
  textAlign(CENTER);
  textSize(40);
  text("Você venceu!", width / 2, height / 2 - 20);
  fill(255);
  textSize(20);
  text("Pontuação: " + score, width / 2, height / 2 + 20);
  text("Pressione R para reiniciar", width / 2, height / 2 + 50);
}

void drawLevelTransition() {
  background(0);
  textAlign(CENTER);
  textSize(36);
  fill(0, 255, 255);
  text("Fase " + (level - 1) + " concluída!", width / 2, height / 2 - 30);
  textSize(20);
  fill(255);
  text("Pressione espaço para continuar", width / 2, height / 2 + 20);
}

void keyPressed() {
  if (enteringName) {
    if (key == ENTER || key == RETURN) {
      if (playerName.length() > 0) {
        enteringName = false;
        gameState = GAME_START;
        loadHighScore();
      }
    } else if (key == BACKSPACE) {
      if (playerName.length() > 0) {
        playerName = playerName.substring(0, playerName.length() - 1);
      }
    } else if (key != CODED && playerName.length() < 12) {
      playerName += key;
    }
    return;
  }

  if (gameState == GAME_START) {
    if (key == 'r' || key == 'R') {
      gameState = GAME_PLAY;
      initGame();
    }
  } else if (gameState == GAME_PLAY) {
    if (keyCode == LEFT) leftPressed = true;
    else if (keyCode == RIGHT) rightPressed = true;
    else if (key == ' ' && canShoot) {
      playerBullets.add(new Bullet(playerX, playerY - playerSize / 2, true));
      canShoot = false;
    }
  } else if (gameState == GAME_OVER || gameState == GAME_WIN) {
    if (key == 'r' || key == 'R') {
      gameState = GAME_START;
      initGame();
    }
  } else if (gameState == GAME_LEVEL_TRANSITION) {
    if (key == ' ') {
      initLevel();
      gameState = GAME_PLAY;
    }
  }
}

void keyReleased() {
  if (keyCode == LEFT) leftPressed = false;
  else if (keyCode == RIGHT) rightPressed = false;
  else if (key == ' ') canShoot = true;
}

class Invader {
  float x, yBase;
  int size;

  Invader(float x, float y) {
    this.x = x;
    this.yBase = y;
    size = invaderSize;
  }

  void display() {
    rectMode(CENTER);
  fill(255, 0, 255);  // cor rosa forte para teste
  rect(x, yBase, size, size);
  
  fill(255);
  textSize(12);
  textAlign(CENTER, CENTER);
}
  
  boolean hitBy(Bullet b) {
    return dist(b.x, b.y, x, yBase) < (b.size + size) / 2;
  }
}

class ShieldInvader extends Invader {
  int hitsRequired = 3;
  int hitsTaken = 0;
  
  ShieldInvader(float x, float y) {
    super(x, y);
  }
  
  void display() {
    if (hitsTaken == 0) {
      fill(0, 200, 200);
    } else if (hitsTaken == 1) {
      fill(0, 150, 150);
    } else {
      fill(0, 100, 100);
    }
    
    rectMode(CENTER);
    rect(x, yBase, size, size);
    
    fill(255);
    textSize(12);
    textAlign(CENTER, CENTER);
    text((hitsRequired - hitsTaken), x, yBase);
  }
  
  boolean hitBy(Bullet b) {
    if (dist(b.x, b.y, x, yBase) < (b.size + size) / 2) {
      hitsTaken++;
      return hitsTaken >= hitsRequired;
    }
    return false;
  }
}

class Bullet {
  float x, y;
  float speed;
  int size = bulletSize;
  boolean playerBullet;

  Bullet(float x, float y, boolean playerBullet) {
    this.x = x;
    this.y = y;
    this.playerBullet = playerBullet;
    speed = playerBullet ? -bulletSpeed : bulletSpeed;
  }

  void update() {
    y += speed;
  }

  void display() {
    fill(playerBullet ? 0 : 255, playerBullet ? 255 : 0, 0);
    ellipse(x, y, size, size);
  }

  boolean offscreen() {
    return y < 0 || y > height;
  }

  boolean hits(Invader inv) {
    return dist(x, y, inv.x, inv.yBase) < (size + inv.size) / 2;
  }

  boolean hits(float px, float py, float psize) {
    return dist(x, y, px, py) < (size + psize) / 2;
  }
}

class WaveBullet extends Bullet {
  float amplitude = 20;
  float frequency = 0.1;
  float startX;
  float startY;
  int age = 0;

  WaveBullet(float x, float y) {
    super(x, y, false);
    startX = x;
    startY = y;
  }

  void update() {
    age++;
    y += speed;
    x = startX + sin(age * frequency) * amplitude;
  }
}

class Boss {
  float x, y;
  int size;
  int health;
  int maxHealth = 20000;
  float speedX;
  int directionX = 1;
  float baseY;
  int shootCooldown = 15;
  int shootTimer = 0;
  int summonTimer = 0;
  boolean summoningEnabled = false;

  ArrayList<Bullet> bossBullets;

  Boss(float x, float y) {
    this.x = x;
    this.y = y;
    this.baseY = y;
    size = 80;
    health = maxHealth;
    speedX = 4;
    bossBullets = new ArrayList<Bullet>();
  }

  void update() {
    x += speedX * directionX;
    if (x < size / 2) {
      directionX = 1;
      y += 15;
      if (y > baseY + 100) y = baseY + 100;
    } else if (x > width - size / 2) {
      directionX = -1;
      y += 15;
      if (y > baseY + 100) y = baseY + 100;
    }
    y += sin(frameCount * 0.05) * 1.5;

    if (!canShoot) {
      shootTimer++;
      if (shootTimer > shootCooldown) {
        canShoot = true;
        shootTimer = 0;
      }
    }

    if (health <= maxHealth/2 && !summoningEnabled) {
      summoningEnabled = true;
    }
    
    if (summoningEnabled) {
      summonTimer++;
      int summonDelay = 180;
      if (health < maxHealth/4) summonDelay = 120;
      
      if (summonTimer > summonDelay) {
        summonTimer = 0;
        summonMinions();
      }
    }

    for (int i = bossBullets.size() - 1; i >= 0; i--) {
      Bullet b = bossBullets.get(i);
      b.update();
      if (b.offscreen()) bossBullets.remove(i);
    }
  }

  void display() {
    fill(255, 100, 0);
    ellipse(x, y, size, size);

    fill(255, 0, 0);
    rectMode(CORNER);
    rect(width/2 - 150, 30, 300 * ((float)health/maxHealth), 20);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(16);
    text(health + "/" + maxHealth, width/2, 40);
    textSize(20);
    text("BOSS", width/2, 15);
  }

  void shootPattern() {
    for (int offsetX = -20; offsetX <= 20; offsetX += 20) {
      bossBullets.add(new Bullet(x + offsetX, y + size / 2, false));
    }
    for (int angle = 0; angle < 180; angle += 45) {
      float rad = radians(angle);
      float bulletX = x + cos(rad) * 30;
      float bulletY = y + sin(rad) * 30 + size / 2;
      bossBullets.add(new WaveBullet(bulletX, bulletY));
    }
  }

  void summonMinions() {
    int minionsToSummon = 3;
    if (health < maxHealth/4) {
      minionsToSummon = 5;
    } else if (health < maxHealth/2) {
      minionsToSummon = 4;
    }
    
    for (int i = 0; i < minionsToSummon; i++) {
      int spawnX = (int)random(invaderSize, width - invaderSize);
      int spawnY = (int)random(invaderSize * 2, height/2);
      invaders.add(new ShieldInvader(spawnX, spawnY));
    }
  }

  boolean hitBy(Bullet b) {
    return dist(b.x, b.y, x, y) < size / 2;
  }

  boolean isDead() {
    return health <= 0;
  }
}

void saveHighScore() {
  String[] data = {playerName, str(highScore)};
  saveStrings("highscore.txt", data);
}

void loadHighScore() {
  String[] data = loadStrings("highscore.txt");
  if (data != null && data.length >= 2) {
    highScoreName = data[0];
    highScore = int(data[1]);
  }
}
