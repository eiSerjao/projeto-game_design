// GalaxyDefenders - Space Invaders com melhorias e chefão

final int GAME_START = 0;
final int GAME_PLAY = 1;
final int GAME_OVER = 2;
final int GAME_WIN = 3;
final int GAME_LEVEL_TRANSITION = 4;

int gameState = GAME_START;

int playerX, playerY;
int playerSize = 40; // Ajustado para melhor visualização da imagem
int playerSpeed = 5;
boolean leftPressed = false;
boolean rightPressed = false;
boolean spacePressed = false;
boolean canShoot = true;

ArrayList<Invader> invaders;
int invaderRows = 4;
int invaderCols = 8;
int invaderSize = 35; // Ajustado para melhor visualização da imagem
int invaderPadding = 15;
float invaderSpeed;
int invaderDirection = 1;
float invaderDrop;
float invaderShootProbability;

ArrayList<Bullet> playerBullets;
ArrayList<Bullet> invaderBullets;
float bulletSpeed;

int bulletSize = 10; // Ajustado para melhor visualização da imagem
int score = 0;
int highScore = 0;
PFont gameFont;

int level = 1;
int maxLevel = 5;

String playerName = "";
String highScoreName = "Sem Nome";
boolean enteringName = true;

Boss boss;

// Variáveis para as imagens
PImage playerImg;
PImage enemyImg;
PImage playerBulletImg;
PImage enemyBulletImg;

void setup() {
  size(600, 700);
  smooth();
  gameFont = createFont("Arial Bold", 32);
  textFont(gameFont);
  loadHighScore();

  // Carregar imagens
  playerImg = loadImage("nave.png");
  enemyImg = loadImage("enemy.png");
  playerBulletImg = loadImage("tiro.png");
  enemyBulletImg = loadImage("fogo.png");

  imageMode(CENTER); // Definir modo de imagem para centro

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
        // Adiciona chance de criar ShieldInvader
        if (level > 1 && random(1) < 0.15 * (level - 1)) { 
           invaders.add(new ShieldInvader(x, y));
        } else {
           invaders.add(new Invader(x, y));
        }
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
  // Desenhar jogador com imagem
  image(playerImg, playerX, playerY, playerSize, playerSize);

  if (leftPressed) playerX -= playerSpeed;
  if (rightPressed) playerX += playerSpeed;

  playerX = constrain(playerX, playerSize / 2, width - playerSize / 2);

  // Atualizar e desenhar balas do jogador
  for (int i = playerBullets.size() - 1; i >= 0; i--) {
    Bullet b = playerBullets.get(i);
    b.update();
    b.display();
    if (b.offscreen()) {
      playerBullets.remove(i);
      // canShoot = true; // Permitir atirar assim que a bala sair da tela
    } else {
      // Colisão com Boss
      if (boss != null) {
        if (boss.hitBy(b)) {
          boss.health -= 100; // Dano aumentado para balancear a vida maior
          playerBullets.remove(i);
          // canShoot = true;
          if (boss.isDead()) {
            boss = null;
            score += 500;
            gameState = GAME_WIN;
            if (score > highScore) {
              highScore = score;
              highScoreName = playerName; // Salvar nome do jogador atual
              saveHighScore();
            }
          }
          continue; // Pula para a próxima bala
        }
      }
      
      // Colisão com Inimigos
      for (int j = invaders.size() - 1; j >= 0; j--) {
        Invader inv = invaders.get(j);
        if (b.hits(inv)) {
          if (inv instanceof ShieldInvader) {
            ShieldInvader shieldInv = (ShieldInvader)inv;
            if (shieldInv.hitBy(b)) { // hitBy já incrementa hitsTaken
              invaders.remove(j);
              score += 20; // Mais pontos por destruir escudos
            }
          } else {
            invaders.remove(j);
            score += 10;
          }
          playerBullets.remove(i);
          // canShoot = true;
          break; // Bala só acerta um inimigo
        }
      }
    }
  }

  // Atualizar e desenhar balas dos inimigos
  for (int i = invaderBullets.size() - 1; i >= 0; i--) {
    Bullet b = invaderBullets.get(i);
    b.update();
    b.display();
    if (b.offscreen()) invaderBullets.remove(i);
    else if (b.hits(playerX, playerY, playerSize)) {
      gameState = GAME_OVER;
      if (score > highScore) {
        highScore = score;
        highScoreName = playerName;
        saveHighScore();
      }
    }
  }

  // Atualizar e desenhar Boss
  if (boss != null && !boss.isDead()) {
    boss.update();
    boss.display();
    boss.shootPattern(); // Boss atira

    // Desenhar e verificar colisão das balas do Boss
    for (int i = boss.bossBullets.size() - 1; i >= 0; i--) {
      Bullet b = boss.bossBullets.get(i);
      b.display();
      if (b.hits(playerX, playerY, playerSize)) {
        gameState = GAME_OVER;
        if (score > highScore) {
          highScore = score;
          highScoreName = playerName;
          saveHighScore();
        }
      }
    }
  } else if (boss == null) { // Só atualiza invaders se não houver boss
    boolean edge = false;
    for (Invader inv : invaders) {
       if (!(inv instanceof ShieldInvader)) { // ShieldInvaders não se movem horizontalmente
         inv.x += invaderSpeed * invaderDirection;
       }
      inv.display();

      // Inimigos atiram
      if (!(inv instanceof ShieldInvader) && random(1) < invaderShootProbability) {
        invaderBullets.add(new Bullet(inv.x, inv.yBase + inv.size / 2, false));
      }

      // Verifica se algum inimigo atingiu a borda
      if (inv.x > width - invaderSize / 2 || inv.x < invaderSize / 2) {
         if (!(inv instanceof ShieldInvader)) { // ShieldInvaders não causam a inversão
            edge = true;
         }
      }
      
      // Verifica se inimigos chegaram perto do jogador
      if (inv.yBase > playerY - playerSize/2 - inv.size/2) {
        gameState = GAME_OVER;
         if (score > highScore) {
           highScore = score;
           highScoreName = playerName;
           saveHighScore();
         }
      }
    }

    // Inverter direção e descer inimigos
    if (edge) {
      invaderDirection *= -1;
      for (Invader inv : invaders) {
        if (!(inv instanceof ShieldInvader)) {
          inv.yBase += invaderDrop;
          // inv.yBase = min(inv.yBase, height - 100); // Evita que saiam da tela por baixo
        }
      }
    }

    // Verificar condição de vitória do nível
    if (invaders.isEmpty()) { // Verifica se a lista está vazia
      if (level >= maxLevel -1 && boss == null) { // Se era o último nível antes do boss
         level++;
         gameState = GAME_LEVEL_TRANSITION;
      } else if (level < maxLevel -1) {
        level++;
        gameState = GAME_LEVEL_TRANSITION;
      } 
      // Se o boss foi derrotado, a transição para GAME_WIN já ocorreu
    }
  }

  // Desenhar informações na tela
  textSize(18);
  fill(255);
  textAlign(LEFT);
  text("Pontos: " + score, 20, 30);
  text("Fase: " + level, 20, 60);
  textAlign(RIGHT);
  text("Recorde: " + highScore + " (" + highScoreName + ")", width - 20, 30);
  text("Jogador: " + playerName, width - 20, 60);
}

void drawGameOver() {
  background(0);
  fill(255, 0, 0);
  textAlign(CENTER);
  textSize(40);
  text("GAME OVER", width / 2, height / 2 - 20);
  textSize(20);
  fill(255);
  text("Pontuação: " + score, width / 2, height / 2 + 20);
  text("Pressione R para reiniciar", width / 2, height / 2 + 50);
}

void drawWinScreen() {
  background(0);
  fill(0, 255, 0);
  textAlign(CENTER);
  textSize(40);
  text("VOCÊ VENCEU!", width / 2, height / 2 - 20);
  fill(255);
  textSize(20);
  text("Pontuação Final: " + score, width / 2, height / 2 + 20);
  text("Pressione R para jogar novamente", width / 2, height / 2 + 50);
}

void drawLevelTransition() {
  background(0);
  textAlign(CENTER);
  textSize(36);
  fill(0, 255, 255);
  if (level == maxLevel) {
     text("Prepare-se para o CHEFE!", width / 2, height / 2 - 30);
  } else {
     text("Fase " + (level) + "", width / 2, height / 2 - 30);
  }
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
        loadHighScore(); // Carrega o high score após nome ser inserido
      }
    } else if (key == BACKSPACE) {
      if (playerName.length() > 0) {
        playerName = playerName.substring(0, playerName.length() - 1);
      }
    } else if ((key >= 'a' && key <= 'z') || (key >= 'A' && key <= 'Z') || (key >= '0' && key <= '9') || key == ' ') {
       if (playerName.length() < 12) {
         playerName += key;
       }
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
      canShoot = false; // Impede tiro contínuo
    }
  } else if (gameState == GAME_OVER || gameState == GAME_WIN) {
    if (key == 'r' || key == 'R') {
      // Reinicia o jogo, mas pede o nome novamente
      enteringName = true; 
      playerName = "";
      // gameState = GAME_START; // Não precisa, enteringName=true já faz isso
      // initGame(); // initGame será chamado após inserir nome
    }
  } else if (gameState == GAME_LEVEL_TRANSITION) {
    if (key == ' ') {
      initLevel(); // Inicia o próximo nível
      gameState = GAME_PLAY;
    }
  }
}

void keyReleased() {
  if (keyCode == LEFT) leftPressed = false;
  else if (keyCode == RIGHT) rightPressed = false;
  else if (key == ' ') canShoot = true; // Permite atirar novamente ao soltar espaço
}

// --- Classes --- 

class Invader {
  float x, yBase;
  int size;

  Invader(float x, float y) {
    this.x = x;
    this.yBase = y;
    size = invaderSize;
  }

  void display() {
    image(enemyImg, x, yBase, size, size);
  }
  
  // Método para verificar colisão (usado pela bala)
  boolean isHit(float bx, float by, float bSize) {
     return dist(bx, by, x, yBase) < (bSize + size) / 2;
  }
}

class ShieldInvader extends Invader {
  int hitsRequired = 3;
  int hitsTaken = 0;
  
  ShieldInvader(float x, float y) {
    super(x, y);
  }
  
  void display() {
    // Desenha a imagem base do inimigo
    image(enemyImg, x, yBase, size, size);
    
    // Desenha uma indicação visual do escudo (opcional, pode ser cor)
    float alpha = map(hitsTaken, 0, hitsRequired, 150, 50); // Escudo fica mais fraco
    fill(0, 150, 255, alpha); // Cor azulada transparente para o escudo
    ellipse(x, yBase, size * 1.1, size * 1.1); // Um pouco maior que o inimigo
    
    // Mostra os hits restantes
    fill(255);
    textSize(12);
    textAlign(CENTER, CENTER);
    text((hitsRequired - hitsTaken), x, yBase);
  }
  
  // Retorna true se o ShieldInvader foi destruído
  boolean hitBy(Bullet b) {
    if (isHit(b.x, b.y, b.size)) { // Usa o método isHit herdado
      hitsTaken++;
      return hitsTaken >= hitsRequired;
    }
    return false;
  }
}

class Bullet {
  float x, y;
  float speed;
  int size;
  boolean playerBullet;

  Bullet(float x, float y, boolean playerBullet) {
    this.x = x;
    this.y = y;
    this.playerBullet = playerBullet;
    this.size = bulletSize; // Usar o bulletSize ajustado
    speed = playerBullet ? -bulletSpeed : bulletSpeed;
  }

  void update() {
    y += speed;
  }

  void display() {
    if (playerBullet) {
      image(playerBulletImg, x, y, size, size);
    } else {
      image(enemyBulletImg, x, y, size * 1.2, size * 1.2); // Bala inimiga um pouco maior
    }
  }

  boolean offscreen() {
    return y < -size || y > height + size; // Considera o tamanho da imagem
  }

  // Colisão com Invader (qualquer tipo)
  boolean hits(Invader inv) {
     return inv.isHit(x, y, size);
  }

  // Colisão com Jogador
  boolean hits(float px, float py, float psize) {
    return dist(x, y, px, py) < (size + psize) / 2;
  }
}

class WaveBullet extends Bullet {
  float amplitude = 20;
  float frequency = 0.1;
  float startX;
  // float startY; // Não precisa, y é atualizado normalmente
  int age = 0;

  WaveBullet(float x, float y) {
    super(x, y, false); // É sempre uma bala inimiga
    startX = x;
    // startY = y;
  }

  void update() {
    age++;
    y += speed; // Movimento vertical normal
    x = startX + sin(age * frequency) * amplitude; // Movimento horizontal senoidal
  }
  
  // Não precisa redefinir display, herda de Bullet
}

class Boss {
  float x, y;
  int size;
  int health;
  int maxHealth = 20000;
  float speedX;
  int directionX = 1;
  float baseY;
  int shootCooldown = 25; // Aumentar um pouco o cooldown
  int shootTimer = 0;
  int specialAttackCooldown = 150; // Cooldown para ataque especial
  int specialAttackTimer = 0;
  int summonTimer = 0;
  boolean summoningEnabled = false;

  ArrayList<Bullet> bossBullets;

  Boss(float x, float y) {
    this.x = x;
    this.y = y;
    this.baseY = y;
    size = 100; // Boss maior
    health = maxHealth;
    speedX = 3; // Boss um pouco mais lento
    bossBullets = new ArrayList<Bullet>();
  }

  void update() {
    // Movimento horizontal
    x += speedX * directionX;
    if (x < size / 2) {
      directionX = 1;
      y += 10; // Desce um pouco ao bater na borda
    } else if (x > width - size / 2) {
      directionX = -1;
      y += 10;
    }
    // Limita o movimento vertical para não descer demais
    y = constrain(y, baseY - 20, baseY + 80);
    
    // Movimento vertical sutil (senoidal)
    y += sin(frameCount * 0.05) * 0.5;

    // Habilitar invocação com metade da vida
    if (health <= maxHealth / 2 && !summoningEnabled) {
      summoningEnabled = true;
    }
    
    // Lógica de invocação
    if (summoningEnabled) {
      summonTimer++;
      int summonDelay = 240; // Invoca a cada 4 segundos
      if (health < maxHealth / 4) summonDelay = 180; // Invoca mais rápido com pouca vida
      
      if (summonTimer > summonDelay) {
        summonTimer = 0;
        summonMinions();
      }
    }

    // Atualizar balas do boss
    for (int i = bossBullets.size() - 1; i >= 0; i--) {
      Bullet b = bossBullets.get(i);
      b.update();
      if (b.offscreen()) bossBullets.remove(i);
    }
    
    // Atualizar timers de ataque
    shootTimer++;
    specialAttackTimer++;
  }

  void display() {
    // Desenhar imagem do Boss
    image(enemyImg, x, y, size, size);

    // Desenhar barra de vida
    rectMode(CORNER);
    // Fundo da barra
    fill(50); 
    rect(width/2 - 150, 10, 300, 20);
    // Vida atual
    fill(255, 0, 0);
    float healthWidth = map(health, 0, maxHealth, 0, 300);
    rect(width/2 - 150, 10, max(0, healthWidth), 20); // Usa max para não ter largura negativa
    // Contorno da barra
    noFill();
    stroke(255);
    strokeWeight(2);
    rect(width/2 - 150, 10, 300, 20);
    noStroke(); // Resetar stroke
    
    // Texto da vida
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(14);
    text(health + " / " + maxHealth, width/2, 20);
    // Texto "BOSS"
    textSize(18);
    text("BOSS", width/2, 45);
    
    rectMode(CENTER); // Resetar rectMode para padrão (embora imageMode seja CENTER)
  }

  // Padrão de tiros do Boss
  void shootPattern() {
    // Tiro normal
    if (shootTimer > shootCooldown) {
       bossBullets.add(new Bullet(x, y + size / 2, false)); // Tiro reto para baixo
       shootTimer = 0;
    }
    
    // Ataque especial (WaveBullets)
    if (specialAttackTimer > specialAttackCooldown) {
       int numWaves = 5;
       if (health < maxHealth / 2) numWaves = 7; // Mais balas com menos vida
       for (int i = 0; i < numWaves; i++) {
          float angle = map(i, 0, numWaves, PI + PI/4, TWO_PI - PI/4); // Espalha para baixo
          float bulletX = x + cos(angle) * 30;
          float bulletY = y + sin(angle) * 30 + size / 3; // Começa um pouco abaixo do centro
          WaveBullet wb = new WaveBullet(bulletX, bulletY);
          wb.amplitude = random(15, 30); // Amplitude variada
          wb.frequency = random(0.08, 0.12); // Frequência variada
          wb.speed = bulletSpeed * 0.8; // Balas wave um pouco mais lentas
          bossBullets.add(wb);
       }
       specialAttackTimer = 0;
    }
  }

  // Invocar inimigos
  void summonMinions() {
    int minionsToSummon = 2;
    if (health < maxHealth / 4) {
      minionsToSummon = 3; // Invoca mais ShieldInvaders com pouca vida
    }
    
    println("Boss summoning " + minionsToSummon + " minions!"); // Debug
    
    for (int i = 0; i < minionsToSummon; i++) {
      // Tenta encontrar uma posição não muito perto de outros inimigos
      float spawnX = random(invaderSize, width - invaderSize);
      float spawnY = random(invaderSize * 2, height / 2 - 50); // Invoca na metade superior
      boolean positionOk = true;
      for(Invader inv : invaders) {
         if (dist(spawnX, spawnY, inv.x, inv.yBase) < invaderSize * 2) {
            positionOk = false;
            break;
         }
      }
      
      if (positionOk) {
         // Adiciona ShieldInvader
         invaders.add(new ShieldInvader(spawnX, spawnY));
      } else {
         println("Failed to find good spawn position for minion");
         // Poderia tentar de novo ou pular este minion
      }
    }
  }

  // Verifica colisão com a bala do jogador
  boolean hitBy(Bullet b) {
    return dist(b.x, b.y, x, y) < size / 2; // Colisão baseada no raio
  }

  boolean isDead() {
    return health <= 0;
  }
}

// --- Funções Auxiliares --- 

void saveHighScore() {
  String[] data = {highScoreName, str(highScore)}; // Salva nome e score
  saveStrings("highscore.txt", data);
  println("High score saved: " + highScoreName + " - " + highScore);
}

void loadHighScore() {
  try {
    String[] data = loadStrings("highscore.txt");
    if (data != null && data.length >= 2) {
      highScoreName = data[0];
      highScore = Integer.parseInt(data[1]);
      println("High score loaded: " + highScoreName + " - " + highScore);
    } else {
      println("No high score file found or invalid format.");
      highScore = 0;
      highScoreName = "Ninguém";
    }
  } catch (Exception e) {
    println("Error loading high score: " + e.getMessage());
    highScore = 0;
    highScoreName = "Ninguém";
  }
}
