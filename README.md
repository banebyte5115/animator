# Animator
Game maker bone animation

# Usage
Create event:
```
skeleton = BA_SkeletonLoad("filename");
animation = BA_AnimationLoad("filename");
```

Step event:
loop = 1;
```
BA_AnimationPlay(skeleton, animation, loop);
```
