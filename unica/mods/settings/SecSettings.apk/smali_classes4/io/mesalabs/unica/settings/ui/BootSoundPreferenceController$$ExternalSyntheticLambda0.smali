.class public final synthetic Lio/mesalabs/unica/settings/ui/BootSoundPreferenceController$$ExternalSyntheticLambda0;
.super Ljava/lang/Object;
.source "D8$$SyntheticClass"

# interfaces
.implements Landroid/media/MediaPlayer$OnErrorListener;


# instance fields
.field public final synthetic f$0:Lio/mesalabs/unica/settings/ui/BootSoundPreferenceController;


# direct methods
.method public synthetic constructor <init>(Lio/mesalabs/unica/settings/ui/BootSoundPreferenceController;)V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    iput-object p1, p0, Lio/mesalabs/unica/settings/ui/BootSoundPreferenceController$$ExternalSyntheticLambda0;->f$0:Lio/mesalabs/unica/settings/ui/BootSoundPreferenceController;

    return-void
.end method


# virtual methods
.method public final onError(Landroid/media/MediaPlayer;II)Z
    .locals 0

    iget-object p0, p0, Lio/mesalabs/unica/settings/ui/BootSoundPreferenceController$$ExternalSyntheticLambda0;->f$0:Lio/mesalabs/unica/settings/ui/BootSoundPreferenceController;

    invoke-virtual {p0}, Lio/mesalabs/unica/settings/ui/BootSoundPreferenceController;->releaseMediaPlayer()V

    const/4 p0, 0x1

    return p0
.end method
