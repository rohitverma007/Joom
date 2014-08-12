#import "RVMyScene.h"
#import "RVPlatform.h"
#import "RVHelper.h"
#import "RVBlocks.h"
#import "RVGameOver.h"

//MOve these to rvhelper maybe?
static const uint32_t ballCat = 1;
static const uint32_t platformCat = 2;
static const uint32_t smallBlockCat = 4;
static const uint32_t bigBlockCat = 8;
static const uint32_t edgeCat = 16;

@implementation RVMyScene
NSMutableArray *platformsArray;
NSMutableArray *smallBlocksArray;
NSMutableArray *bigBlocksArray;
SKSpriteNode *ball;
//SKSpriteNode *platform;
BOOL touchingGround = NO;
RVPlatform *platform;
RVPlatform *platform1;
SKSpriteNode *smallBlock;
SKSpriteNode *bigBlock;
RVPlatform *platform2;
RVBlocks *smallBlockObj;
RVBlocks *bigBlockObj;
SKLabelNode *score;
SKLabelNode *healthNumber;
SKAction *forever;
BOOL addedPlatform = NO;
float totalWidth = 0;
float oldSize = 0;
float lastSmallBlockSize = 0;
float lastBigBlockSize = 0;
const int rWIDTH = 1;
const int rSPACE = 2;
int currentScore = 0;
BOOL appliedImpulse = false;
BOOL onAir = false;
int touched = 0;
bool addedBigBlocks = false;
bool addedSmallBlocks = false;
bool setMultipleLayer = false;
int newLayerY;
NSUserDefaults *defaults;
int numberOfBlocks;
int health;
int speedLevel;
bool noRedLevel;
bool paused;


-(SKAction*)getAction{
    return forever;
}

-(void)setAction:(SKAction*)movePlat :(BOOL)isForever{
    
    SKAction* movePlatform = movePlat;
    if(isForever){
        forever = [SKAction repeatActionForever:movePlatform];
    } else {
        forever = movePlatform;
    }
    
}

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor blueColor];
        self.physicsWorld.contactDelegate = self;
        defaults = [NSUserDefaults standardUserDefaults];
        int level = (int)[defaults integerForKey:@"level"];
        currentScore = 0;
        numberOfBlocks = 5;
        health = level;
        speedLevel = 0;
        
        //Preload Audio
        SKAction *preloadHit = [SKAction playSoundFileNamed:@"Hit_Hurt14.wav" waitForCompletion:false];
        SKAction *preloadCoin = [SKAction playSoundFileNamed:@"Pickup_Coin16.wav" waitForCompletion:false];
        
        SKSpriteNode *edges = [[SKSpriteNode alloc] init];
        edges.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(1, 0) toPoint:CGPointMake(size.width, 0)];
        edges.physicsBody.categoryBitMask = edgeCat;
        
        SKSpriteNode *edgesSide = [[SKSpriteNode alloc] init];
        edgesSide.physicsBody = [SKPhysicsBody bodyWithEdgeFromPoint:CGPointMake(0, 1) toPoint:CGPointMake(0, size.height)];
        edgesSide.physicsBody.categoryBitMask = edgeCat;
        
        [self addChild:edges];
        [self addChild:edgesSide];
        //        [self addChild:edgesRightSide];
        platformsArray = [NSMutableArray array];
        
        platform = [[RVPlatform alloc ]init:size];
        [platform setPosition:CGPointMake(platform.size.width/2, platform.size.height/2)];
        
        [self setAction:[SKAction moveBy:CGVectorMake(-350, 0) duration: 3] :true];
        
        [platform runAction:[self getAction]];
        [platformsArray addObject:platform];
        
        [platformsArray addObject:[[[RVPlatform alloc]init:self.size] setNewPositionAndRunAction:(int)([RVHelper getDistance:platformsArray.lastObject]) :[self getAction]]];
        
        [platformsArray addObject:[[[RVPlatform alloc]init:self.size] setNewPositionAndRunAction:(int)([RVHelper getDistance:platformsArray.lastObject]) :[self getAction]]];
        
        for(int i = 0; i < [platformsArray count]; i++){
            [self addChild:platformsArray[i]];
        }
        
        
        //TODO - Move into a function or seperate class for reuse in other scenes
        ball = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:CGSizeMake(25, 25)];
        ball.position = CGPointMake(ball.size.width/2+20, self.size.height/2);
        ball.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:ball.size];
        ball.physicsBody.friction = 0;
        ball.physicsBody.categoryBitMask = ballCat;
        ball.physicsBody.contactTestBitMask = smallBlockCat | platformCat | bigBlockCat | edgeCat | 32;
        ball.physicsBody.collisionBitMask = platformCat;
        ball.physicsBody.allowsRotation = NO;
        
        //TODO Maybe move these two functions to a class for reuse in other scenes? -Done?
        
        
        smallBlocksArray = [NSMutableArray array];
        
        bigBlocksArray = [NSMutableArray array];
        [self generateBigBlocks:size];
        
        
        [self generateSmallBlocks:size :arc4random_uniform(numberOfBlocks)];
        
        //Helper function maybe?
        score = [SKLabelNode labelNodeWithFontNamed:@"AppleSDGothicNeo-Regular"];
        score.fontSize = 20;
        score.text = [NSString stringWithFormat:@"Score: %d", currentScore];
        score.position = CGPointMake(size.width/2+150, size.height-40);
        [self addChild:score];
        
        healthNumber = [SKLabelNode labelNodeWithFontNamed:@"AppleSDGothicNeo-Regular"];
        healthNumber.fontSize = 20;
        healthNumber.text = [NSString stringWithFormat:@"Health: %d", health];
        healthNumber.position = CGPointMake(150, size.height-40);
        [self addChild:healthNumber];
        
        [self addChild:ball];
        
        SKSpriteNode *pauseButtonFirstHalf = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:1 green:1 blue:1 alpha:0.7] size:CGSizeMake(10, 20)];
        pauseButtonFirstHalf.position = CGPointMake(size.width/2, size.height-30);
        pauseButtonFirstHalf.name = @"pauseButton";
        
        SKSpriteNode *pauseButtonSecondHalf = [SKSpriteNode spriteNodeWithColor:[SKColor colorWithRed:1 green:1 blue:1 alpha:0.7] size:CGSizeMake(10, 20)];
        pauseButtonSecondHalf.position = CGPointMake(pauseButtonFirstHalf.position.x+pauseButtonFirstHalf.size.width/2+10, size.height-30);
        pauseButtonSecondHalf.name = @"pauseButton1";

        paused = false;
        [self addChild:pauseButtonFirstHalf];
        [self addChild:pauseButtonSecondHalf];

        
        
        
    }
    return self;
}

-(void)generateSmallBlocks:(CGSize)size :(int)count{
    
    
    
    
    [smallBlocksArray addObject:[[[RVBlocks alloc]init:size :true] setNewPositionAndRunAction:self.size.width+10 :[self getAction] :self.size :setMultipleLayer :smallBlocksArray.lastObject :(int)newLayerY :true]];
    [self addChild:smallBlocksArray.lastObject];
    
    for(int i = 1; i < count; i++){
        RVBlocks *abcd = smallBlocksArray.lastObject;
        
        if(i > 3){
            setMultipleLayer = true;
        }
        
        if(i == 4){
            CGPoint last = [smallBlocksArray.lastObject position] ;
            abcd.position = CGPointMake(abcd.position.x, abcd.position.y);
            newLayerY = last.y;
        }
        [smallBlocksArray addObject:[[[RVBlocks alloc]init:size :true] setNewPositionAndRunAction:(int)([RVHelper getSmallBlocksDistance:abcd]) :[self getAction] :self.size :setMultipleLayer :smallBlocksArray.lastObject  :(int)newLayerY :true]];
        
        [self addChild:smallBlocksArray.lastObject];
        
    }
    
    setMultipleLayer = false;
    
}

-(void)generateBigBlocks:(CGSize)size{
    [bigBlocksArray addObject:[[[RVBlocks alloc]init:size :false] setNewPositionAndRunAction:500  :[self getAction] :self.size :setMultipleLayer :platformsArray.lastObject :(int)newLayerY :false]];
    [platformsArray.lastObject addChild:bigBlocksArray.lastObject];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    

    if(onAir == false && paused == false){
        touched++;
        appliedImpulse = true;
        [ball.physicsBody applyImpulse:CGVectorMake(0, 12)];
    }
    
    if(paused == true){
        paused = false;
        self.view.paused = false;
    }
    
    
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    if([node.name isEqualToString:@"pauseButton"] || [node.name isEqualToString:@"pauseButton1"]){
        paused = true;
        self.view.paused = true;
    }
    

    
    
}


-(void)didBeginContact:(SKPhysicsContact *)contact{
    SKPhysicsBody *notBall;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask){
        
        notBall = contact.bodyB;
    } else {
        notBall = contact.bodyA;
        
    }
    
    
    if(notBall.categoryBitMask == smallBlockCat){
        [self runAction:[SKAction playSoundFileNamed:@"Pickup_Coin16.wav" waitForCompletion:false]];
        [notBall.node removeFromParent];
        currentScore++;
        score.text = [NSString stringWithFormat:@"Score: %d", currentScore];
        
        if([notBall.node.name isEqualToString:@"lastSmallBlock"]){
            [self generateSmallBlocks:self.frame.size :arc4random_uniform(numberOfBlocks)];
        }
    }
    

    if(notBall.categoryBitMask == bigBlockCat){
        health--;
        healthNumber.text = [NSString stringWithFormat:@"Health: %d", health];
        
        void (^callBack)(void) = ^(void){
            [notBall.node removeFromParent];
            
            score.text = [NSString stringWithFormat:@"Score: %d", currentScore];
            if(health <= 0){
                
                
                if([defaults objectForKey:@"highScore"] == nil){
                    
                    [defaults setInteger:0 forKey:@"highScore"];
                    
                }
                if([defaults objectForKey:@"totalScore"] == nil){
                    
                    [defaults setInteger:0 forKey:@"totalScore"];
                    
                }
                
                int totalScore = [defaults integerForKey:@"totalScore"];
                
                
                if(currentScore > [defaults integerForKey:@"highScore"]){
                    [defaults setInteger:(int)currentScore forKey:@"highScore"];
                }
                
                
                totalScore += currentScore;
                [defaults setInteger:(int)currentScore forKey:@"score"];
                [defaults setInteger:(int)totalScore forKey:@"totalScore"];
                
                
                SKTransition *reveal = [SKTransition revealWithDirection:SKTransitionDirectionDown duration:0.5];
                RVGameOver *newScene = [[RVGameOver alloc] initWithSize:self.size];
                [self.scene.view presentScene: newScene transition:reveal];
                
                if([notBall.node.name isEqualToString:@"lastBigBlock"]){ //TODO what ? is this needed?
                    [self generateBigBlocks:self.frame.size];
                }
            }
            
        };
        
        
        
        [self runAction:[SKAction playSoundFileNamed:@"Hit_Hurt14.wav" waitForCompletion:true] completion:callBack];
        
    }
    
    
    if(notBall.categoryBitMask == platformCat){
        onAir = false;
    }
    
    if(notBall.categoryBitMask == edgeCat){
        void (^newCallback)(void) = ^(void){
            
            
            
            score.text = [NSString stringWithFormat:@"Score: %d", currentScore];
            
            
            if([defaults objectForKey:@"highScore"] == nil){
                
                [defaults setInteger:0 forKey:@"highScore"];
                
            }
            
            if([defaults objectForKey:@"totalScore"] == nil){
                
                [defaults setInteger:0 forKey:@"totalScore"];
                
            }
            
            int totalScore = [defaults integerForKey:@"totalScore"];
            
            if(currentScore > [defaults integerForKey:@"highScore"]){
                [defaults setInteger:(int)currentScore forKey:@"highScore"];
            }
            
            
            totalScore += currentScore;
            [defaults setInteger:(int)currentScore forKey:@"score"];
            [defaults setInteger:(int)totalScore forKey:@"totalScore"];
            
            
            SKTransition *reveal = [SKTransition revealWithDirection:SKTransitionDirectionDown duration:1.0];
            RVGameOver *newScene = [[RVGameOver alloc] initWithSize:self.size];
            [self.scene.view presentScene: newScene transition:reveal];
        };
        
        [self runAction:[SKAction playSoundFileNamed:@"Hit_Hurt14.wav" waitForCompletion:true] completion:newCallback];
        
    }
}

-(void)generatePlatforms{
    
    [platformsArray addObject:[[[RVPlatform alloc]init:self.size] setNewPositionAndRunAction:(int)([RVHelper getDistance:platformsArray.lastObject]) :[self getAction]]];
    [self addChild:platformsArray.lastObject];
    
    [platformsArray addObject:[[[RVPlatform alloc]init:self.size] setNewPositionAndRunAction:(int)([RVHelper getDistance:platformsArray.lastObject]) :[self getAction]]];
    [self addChild:platformsArray.lastObject];
    
    [platformsArray addObject:[[[RVPlatform alloc]init:self.size] setNewPositionAndRunAction:(int)([RVHelper getDistance:platformsArray.lastObject]) :[self getAction]]];
    [self addChild:platformsArray.lastObject];
}

-(void)update:(CFTimeInterval)currentTime {
    
    
    
    
    CGPoint lastObject = [platformsArray.lastObject position];
    CGPoint lastBigBlockPosition = [[bigBlocksArray.lastObject parent] position];
    
    if(currentScore > 15 && speedLevel == 0){
        speedLevel = 1;
        numberOfBlocks += 3;
        [self setAction:[SKAction moveBy:CGVectorMake(-500, 0) duration: 2.5] :true];
        
    }
    
    
    //    if(currentScore > 25 && lastObject.x < self.size.width){
    //        NSLog(@"hi %d", currentScore);
    //        [self setAction:[SKAction moveBy:CGVectorMake(-500, 0) duration: 3] :true];
    //    }
    
    if(currentScore > 50 && speedLevel == 1){
        speedLevel = 2;
        
        numberOfBlocks += 2;
        [self setAction:[SKAction moveBy:CGVectorMake(-750, 0) duration: 3] :true];
    }
    
    if(currentScore > 100 && speedLevel == 2){
        speedLevel = 3;
        
        numberOfBlocks += 1;
        [self setAction:[SKAction moveBy:CGVectorMake(-1000, 0) duration: 3] :true];
    }
    
    
    if(currentScore > 150 && speedLevel == 3){
        speedLevel = 4;
        
        numberOfBlocks += 2;
        [self setAction:[SKAction moveBy:CGVectorMake(-1250, 0) duration: 3] :true];
    }
    
    if(currentScore > 200 && speedLevel == 4){
        speedLevel = 5;
        numberOfBlocks += 1;
        
        [self setAction:[SKAction moveBy:CGVectorMake(-1750, 0) duration: 3] :true];
    }
    
    if(!addedBigBlocks){
        if(lastBigBlockPosition.x < self.size.width/2){
            addedBigBlocks = true;
            [self generateBigBlocks:self.size];
        }
    }
    
    if(addedBigBlocks){
        if(lastBigBlockPosition.x < self.size.width/2){
            addedBigBlocks = false;
        }
    }
    
    CGPoint lastSmallBlockPosition = [smallBlocksArray.lastObject position];
    
    if(!addedSmallBlocks){
        if(lastSmallBlockPosition.x < self.size.width/2){
            addedSmallBlocks = true;
            [self generateSmallBlocks:self.size :arc4random_uniform(numberOfBlocks)]; //TODO determine if needed in both here and touching blocks!
        }
    }
    
    if(addedSmallBlocks){
        if(lastSmallBlockPosition.x < self.size.width/2){
            addedSmallBlocks = false;
        }
    }
    
    
    if(!addedPlatform){
        if(lastObject.x < self.size.width){
            addedPlatform = YES;
            [self generatePlatforms];
        }
    }
    
    if(touched == 2){
        touched = 0;
        onAir = true;
    }
    
    if(addedPlatform){
        if(lastObject.x < self.size.width){
            addedPlatform = NO;
        }
    }
    
    
}

@end
