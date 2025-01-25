// やること
// 未来の自分のためにプログラムを分かりやすいよう整理する
// 引継ぎ資料と報告書を書く
// 残機の実装：1回or2回までミスしてOKにする  (これの実装は直前でも良い)
// スコアの計算方法や制限時間など細かいルールを決める   (これも直前で良い)

import kinect4WinSDK.*;                       // kinect4WinSDK ライブラリを使う

Kinect kine = new Kinect(this);               // Kinect オブジェクト "kine" の宣言
SkeletonData user;                            // SkeletonData オブジェクト "user" の宣言
// PImage backImage;                             // 背景画像用の PImage "backImage" の宣言

// ブロックを番号を付けて管理するリスト
ArrayList<Integer> blockid = new ArrayList<Integer>();

// ボールの挙動を計算するための変数
float radius = 5;                       // ボールの半径
float x0, y0;                           // ボールの初期位置
float vx0 = 0, vy0 = 12;                // ボールの初期速度
float v = sqrt(vx0 * vx0 + vy0 * vy0);  // ボールの速さ
float x1, y1;                           // 左手の座標
float x2, y2;                           // 右手の座標
float x, y;                             // ボールの座標
float vx, vy;                           // ボールの速度
float prex1, prey1;                     // 1フレーム前の左手の座標
float prex2, prey2;                     // 1フレーム前の右手の座標

//ブロック作成用
int rows;      // ブロックの行数
int cols;      // ブロックの列数
int blockWidth;  // ブロックの幅
int blockHeight; // ブロックの高さ
int padding;     // ブロック間のスペース
int startX;      // ブロックの配置開始位置（x座標）
int startY = 50;      // ブロックの配置開始位置（y座標）
int level = 1;        // ブロック配置のレベル
int NumberofBlock;    // ブロックの数

// ゲームモードに関わる変数
// modeが3ならプレイモード、1ならゲームオーバー、2ならゲームクリア、0ならスタンバイ、4ならカウントダウン
// bar_touchingが0ならバーと触れていない、1なら触れている
int mode;              // ゲームモード
int score;             // スコア
int bar_touching;      // バーとの接触判定
int time;              // 各モードが始まってからの時間
int basetime;          // 各モードが始まった時刻
int timelimit;         // ゲームの制限時間

// 画像の準備
// PImage background;   // 背景画像用
PImage gameover;     // ゲームオーバーのロゴ
PImage gameclear;    // ゲームクリアのロゴ

// drawの前に実行される関数。下準備。
void setup() {
    size(640, 640);                             // ウィンドウのサイズ設定
    //backImage = loadImage("back.jpg");          // 背景画像の読み込み
    user = new SkeletonData();                  // SkeletonData のインスタンス化
    init_variable();   // 変数の初期化
    //画像読み込み
    gameover = loadImage("gameover.png");
    gameover.resize(width / 2, 0);         // サイズ調整
    gameclear = loadImage("gameclear.png");
    gameclear.resize(width / 2, 0);        // サイズ調整
}

void draw() {
    background(0);                              // 背景を黒く塗りつぶす
    //image(backImage, 0, 0, 640, 640);         // 背景画像を描画したい場合はここで
    image(kine.GetMask(), 0, 0, 640, 640);      // Kinect の人物マスク画像を描画
    
    draw_bar();                                 // バーを描画
    draw_block();                               // ブロックを描画
    score = NumberofBlock - blockid.size();       // スコア計算。現在は消したブロックの数
    textSize(30);                               // 以下3行でスコアを表示
    fill(255, 255, 255);
    textAlign(LEFT, BASELINE);
    text("SCORE:" + score, 30, 35);
    
    //ゲームプレイ時の処理
    if(mode == 3) {
        next_ball_position();                       // ボールの位置を計算
        draw_ball();                                // ボールを描画
        
        time= floor((millis() - basetime) / 1000);
        int resttime = timelimit - time;            // 残り時間
        textSize(30);                               // 以下3行で残り時間を表示
        fill(255, 255, 255);
        textAlign(LEFT, BASELINE);
        text("TIME:" + resttime, width - 120, 35);
        if (resttime == 0) {                        // 残り時間が0になるとゲームオーバー
            mode =1;
        }
    }
    
    //ゲームオーバー時の処理
    else if (mode == 1) {
        image(gameover,(width - gameover.width) / 2,(height - gameover.height) / 2);
    }
    
    //ゲームクリア時の処理
    else if (mode == 2) {
        image(gameclear,(width - gameclear.width) / 2,(height - gameclear.height) / 2);
    }
    
    //スタンバイ時の処理
    else if (mode == 0) {
        next_ball_position();                       // ボールの位置を計算
    }
    
    //カウントダウンの処理
    else if (mode == 4) {
        time= floor((millis() - basetime) / 1000);
        textSize(60);
        textAlign(CENTER, CENTER); // 中央揃え（水平: CENTER, 垂直: CENTER）
        fill(255, 255, 255);
        text(5 - time, width / 2, height / 2);
        if (5 - time == 0) {
            gamestart();
        }
    }
}

// 人物が検出された時に実行される appearEvent 関数
void appearEvent(SkeletonData sd) {
    user = sd;                                  // 検出された人物をuserに入れる
}

// 人物がいなくなった時に実行される disappearEvent 関数
void disappearEvent(SkeletonData sd) {
    user = null;                                // userを空（null）にする
}

// バーを描画する
void draw_bar() {
    if (user == null) {                          // userが空なら
        return;                                   // 何もしないで関数を抜ける
    }
    colorMode(RGB);                             // 色の指定を RGB 形式にする
    noStroke();                                 // 線は描かない
    fill(255, 255, 255);                        // 塗りつぶす色の指定 (Red, Green, Blue)
    //関節の位置に円を描く（右手、左手）
    prex1 = x1;
    prey1 = y1;
    prex2 = x2;
    prey2 = y2;
    x1= user.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HAND_LEFT].x * width;
    y1= user.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HAND_LEFT].y * height;
    x2= user.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HAND_RIGHT].x * width;
    y2= user.skeletonPositions[Kinect.NUI_SKELETON_POSITION_HAND_RIGHT].y * height;
    
    //手の動く速度が一定以上の時、バーの速度に上限を設ける（速度上限＝ボールの速度）
    if((prex1 - x1) * (prex1 - x1) + (prey1 - y1) * (prey1 - y1) > v * v) {
        //println(x1, y1);
        x1 =prex1 + (x1 - prex1) * v / sqrt((prex1 - x1) * (prex1 - x1) + (prey1 - y1) * (prey1 - y1));
        y1 =prey1 + (y1 - prey1) * v / sqrt((prex1 - x1) * (prex1 - x1) + (prey1 - y1) * (prey1 - y1));
        //println(x1, y1);
    }
    if((prex2 - x2) * (prex2 - x2) + (prey2 - y2) * (prey2 - y2) > v * v) {
        x2 =prex2 + (x2 - prex2) * v / sqrt((prex2 - x2) * (prex2 - x2) + (prey2 - y2) * (prey2 - y2));
        y2 =prey2 + (y2 - prey2) * v / sqrt((prex2 - x2) * (prex2 - x2) + (prey2 - y2) * (prey2 - y2));
        //println(x2, y2);
    }
    
    ellipse(x1, y1, 10, 10);
    ellipse(x2, y2, 10, 10);
    
    //手と手の間に線を描く
    stroke(255, 255, 255);                      // 線を描く (Red, Green, Blue)
    strokeWeight(10);                            // 先の太さ
    noFill();                                   // 塗りつぶさない
    line(x1, y1, x2, y2);
}

// ボールの位置を計算する関数
void next_ball_position() {
    //壁に当たった時の処理。左右の壁に当たったらvxを、上の壁に当たったらvyを反転
    if(x <= radius || x >= 639 - radius) {
        vx =-vx;
    }
    if(y <= radius) {
        vy =-vy;
    }
    //下の壁に当たったらゲームオーバー。モード管理のフラグを1にする
    if(y >= 639 - radius) {
        vy =0;
        mode= 1;
    }
    
    //バーに当たった時の反射を計算する時に使う変数
    //a、bはバーを直線の式y = ax + bで表した時のa、b
    float a, b;
    if(abs(x2 - x1) < 0.001) { // バーが垂直に近い場合
        a = Float.POSITIVE_INFINITY; // 傾きを無限大とみなす
        b = 0; // 使用しない
    } else {
        a = (y2 - y1) / (x2 - x1);
        b = y1 - a * x1;
    }
    
    //dはバーとボールとの距離、d_leftとd_rightはボールと左手/右手との距離
    float d;
    if(abs(x2 - x1) < 0.001) {
        d = abs(x - x1); // 垂直バーとの距離
    } else {
        d = abs(a * x - y + b) / sqrt(a * a + 1);
    }
    float d_left = sqrt((x - x1) * (x - x1) + (y - y1) * (y - y1));
    float d_right = sqrt((x - x2) * (x - x2) + (y - y2) * (y - y2));
    
    //次のボールの位置を仮定
    float nextX = x + vx, nextY = y + vy;
    
    //バーとの衝突
    //左右の端点に当たった場合の処理。現在はvxとvyを入れ替えるようにしている。
    if(d_left <= radius + 8 || d_right <= radius + 8) {
        float s = vx;
        vx =vy;
        vy =s;
    }
    //端点以外に当たった時の処理。
    //時々おかしな挙動をすることが有るので、もっと良い書き方があるかも。
    else if (mode == 3 && x >= min(x1, x2) && x <= max(x1, x2) && (d <= radius + 2 || abs(nextY - a * nextX - b) <= radius + 8) && bar_touching == 0) {
        bar_touching = 1;
        // 移動経路を線分として扱い、バーとの交差をチェック
        float denom = a * (nextX - x) - (nextY - y);
        if (denom != 0) { // ボールの線分とバーが平行でない場合
            float t = (a * x - y + b) / denom; // ボール線分上の衝突点割合
           if (t >= 0 && t <= 1) { // 衝突がフレーム内で発生
                // 衝突位置を計算
               x += t *(nextX - x);
               y += t *(nextY - y);
                draw_ball();
        }
        }
        
        // 法線ベクトルの計算
        float nx = -a; // y = ax + b の法線は y = -1/a x
        float ny = 1;
        float len = sqrt(nx * nx + ny * ny);
        nx /= len;
        ny /= len;
        
        // 反射計算
        float dot = vx * nx + vy * ny;
        vx -= 2 * dot * nx;
        vy -= 2 * dot * ny;
        
        // 誤差の蓄積でボールの速さが変わらないように速度ベクトルの大きさを一定に保つ。
        float vc = sqrt(vx * vx + vy * vy);
        vx =vx * v / vc;
        vy =vy * v / vc;
    }
    else if (mode == 3 && bar_touching == 1 && (d > radius + 15 || abs(nextY - a * nextX - b) > radius + 20)) {
        bar_touching = 0;
    }
    
    //ブロックとの衝突
    //削除するブロックのIDを挿入するリスト
    ArrayList<Integer> toRemove = new ArrayList<Integer>();
    for (int i = 0; i < blockid.size(); i++) {
        // i= j * cols + k と表せるとき、iはj行k列目のブロック
        int col = blockid.get(i) % cols;
        int row = blockid.get(i) / cols;
        // ブロックの位置を計算
        int blockx = startX + col * (blockWidth + padding);
        int blocky = startY + row * (blockHeight + padding);
        // 描画の都合上の補正
        float rad = radius + 8;
        
        if (x + rad > blockx && x - rad < blockx + blockWidth && 
            y + rad > blocky && y - rad < blocky + blockHeight) {
           // 衝突面を判定して速度を反転
           if ((y- rad < blocky && vy > 0) || (y + rad > blocky + blockHeight && vy < 0)) {
               vy = -vy;  // Y方向の反転
        } else if ((x - rad < blockx && vx > 0) || (x + rad > blockx + blockWidth && vx < 0)) {
               vx = -vx;  // X方向の反転
        }
            toRemove.add(i); // 削除対象を記録
        }
    }
    
    //ブロック削除処理
    for (int i = toRemove.size() - 1; i >= 0; i--) {
        blockid.remove((int)toRemove.get(i));
    }
    
    //速度が決まったので次のボールの位置も決定。
    x += vx;
    y += vy;
}

// ボールを描画するだけの関数。色を変えたかったらfillの引数を変える。
void draw_ball() {
    fill(255, 255, 255);
    ellipse(x, y, 2 * radius, 2 * radius);
}

// ブロックを描画する関数。
void draw_block() {
    if(blockid.isEmpty()) {
        mode= 2;
}
    else {
        startX = (640 - (cols * blockWidth + (cols - 1) * padding)) / 2;
        for (int i = 0; i < blockid.size(); i++) {
           // 各ブロックの位置を計算
            int col = blockid.get(i) % cols;
            int row = blockid.get(i) / cols;
            int blockx = startX + col * (blockWidth + padding);
            int blocky = startY + row * (blockHeight + padding);
            
           // 色を設定
           if (level == 1) {
                fill(map(row, 0, rows - 1, 50, 255), 100, 200);
        }
        // ③
           if (level == 2) {
                int[] green = {0, 1, 3, 4, 8, 9, 14, 17, 19};
                if (contains(green, blockid.get(i))) {
                    fill(0, 255, 0);
                }
            else{
                    fill(map(row, 0, rows - 1, 50, 255), 100, 200);
                }
        }
           if (level == 3) {
                fill(map(row, 0, rows - 1, 50, 255), 100, 200);
        }
            
           // ブロックを描画
            strokeWeight(0.5);
            rect(blockx, blocky, blockWidth, blockHeight);
        }
    }
}

// 変数初期化用関数
void init_variable() {
    x0= width / 2;      // ボールの初期位置
    y0= height / 2;
    x = x0;             // ボールを初期位置に配置
    y = y0;
    vx= 0;              // ボールの初期速度
    vy= 0;
    
    mode = 0;           // ゲームモード
    score = 0;          // スコア
    bar_touching = 0;   // バーとの接触判定
    
    blockid.clear();       // ブロック番号の初期化
    // ①
    if(level == 1) {       // レベルごとのブロックの設定
        rows= 3;           // ブロックの行数
        cols= 6;           // ブロックの列数
        blockWidth = 80;   // ブロックの横幅
        blockHeight = 30;  // ブロックの高さ
        padding = 5;       // ブロック間の幅
        startX = (640 - (cols * blockWidth + (cols - 1) * padding)) / 2;  // ブロックを中央に揃える
        for (int i = 0; i < rows * cols; i++) {  // ブロックを配置したい位置の番号を追加する
            blockid.add(i);
        }
        NumberofBlock = blockid.size();  // ブロックの数を記録
        timelimit = 1000;  // 制限時間
    }
    
    else if(level == 2) {
        rows= 4;
        cols= 5;
        blockWidth = 80;
        blockHeight = 30;
        padding = 5;
        startX = (640 - (cols * blockWidth + (cols - 1) * padding)) / 2;
        for (int i = 0; i < rows * cols; i++) {
            blockid.add(i);
        }
        NumberofBlock = blockid.size();
        timelimit = 1000;
    }
    
    else if(level == 3) {
        rows= 6;
        cols= 7;
        blockWidth = 80;
        blockHeight = 30;
        padding = 5;
        startX = (640 - (cols * blockWidth + (cols - 1) * padding)) / 2;
        // ②
        int[] blocktrue = {0, 1, 3, 4, 8, 9, 14, 17, 19, 23, 26, 29, 32, 36, 39, 41};
        for (int i = 0; i < rows * cols; i++) {
            if (contains(blocktrue, i)) {
                    blockid.add(i);
            }
        }
        NumberofBlock = blockid.size();
        timelimit = 1000;
    }
}

// キー入力を感知する関数
void keyPressed() {
    if(key == 'r' && mode != 3) {   // プレイモードでない時、rを押すとリセット
        init_variable();
    }
    else if(mode == 0) {   // スタンバイの時、数字キーを押すと対応するレベルのブロック配置に変わる
        // ④
        if (key == '1') {
            level = 1;
            init_variable();
        }
        if (key == '2') {
            level = 2;
            init_variable();
        }
        if (key == '3') {
            level = 3;
            init_variable();
        }
        
        // Sキーを押すとカウントダウンモードに移行。5カウント後にゲームが始まる。
        if (key == 's') {
            mode =4;
            basetime = millis();
        }
    }
}

// ゲームをスタートする関数
void gamestart() {
    vx= vx0;
    vy= vy0;
    mode = 3;
    basetime = millis();
}

// 配列に要素が含まれているかチェックする関数
boolean contains(int[] array, int value) {
    for (int val : array) {
        if (val == value) {
            return true;
        }
    }
    return false;
}