.class public final Lio/mesalabs/unica/search/UnicaSearchIndexableResources;
.super Lcom/android/settingslib/search/SearchIndexableResourcesMobile;
.source "UnicaSearchIndexableResources.java"


# direct methods
.method public constructor <init>()V
    .locals 3

    invoke-direct {p0}, Lcom/android/settingslib/search/SearchIndexableResourcesMobile;-><init>()V

    new-instance v0, Lcom/android/settingslib/search/SearchIndexableData;

    const-class v1, Lio/mesalabs/unica/settings/UnicaSettingsFragment;

    sget-object v2, Lio/mesalabs/unica/settings/UnicaSettingsFragment;->SEARCH_INDEX_DATA_PROVIDER:Lcom/android/settings/search/BaseSearchIndexProvider;

    invoke-direct {v0, v1, v2}, Lcom/android/settingslib/search/SearchIndexableData;-><init>(Ljava/lang/Class;Lcom/android/settingslib/search/Indexable$SearchIndexProvider;)V

    invoke-virtual {p0, v0}, Lio/mesalabs/unica/search/UnicaSearchIndexableResources;->addIndex(Lcom/android/settingslib/search/SearchIndexableData;)V

    new-instance v0, Lcom/android/settingslib/search/SearchIndexableData;

    const-class v1, Lio/mesalabs/unica/settings/extra/ExtraSettingsFragment;

    sget-object v2, Lio/mesalabs/unica/settings/extra/ExtraSettingsFragment;->SEARCH_INDEX_DATA_PROVIDER:Lcom/android/settings/search/BaseSearchIndexProvider;

    invoke-direct {v0, v1, v2}, Lcom/android/settingslib/search/SearchIndexableData;-><init>(Ljava/lang/Class;Lcom/android/settingslib/search/Indexable$SearchIndexProvider;)V

    invoke-virtual {p0, v0}, Lio/mesalabs/unica/search/UnicaSearchIndexableResources;->addIndex(Lcom/android/settingslib/search/SearchIndexableData;)V

    new-instance v0, Lcom/android/settingslib/search/SearchIndexableData;

    const-class v1, Lio/mesalabs/unica/settings/spoof/SpoofSettingsFragment;

    sget-object v2, Lio/mesalabs/unica/settings/spoof/SpoofSettingsFragment;->SEARCH_INDEX_DATA_PROVIDER:Lcom/android/settings/search/BaseSearchIndexProvider;

    invoke-direct {v0, v1, v2}, Lcom/android/settingslib/search/SearchIndexableData;-><init>(Ljava/lang/Class;Lcom/android/settingslib/search/Indexable$SearchIndexProvider;)V

    invoke-virtual {p0, v0}, Lio/mesalabs/unica/search/UnicaSearchIndexableResources;->addIndex(Lcom/android/settingslib/search/SearchIndexableData;)V

    new-instance v0, Lcom/android/settingslib/search/SearchIndexableData;

    const-class v1, Lio/mesalabs/unica/settings/ui/UISettingsFragment;

    sget-object v2, Lio/mesalabs/unica/settings/ui/UISettingsFragment;->SEARCH_INDEX_DATA_PROVIDER:Lcom/android/settings/search/BaseSearchIndexProvider;

    invoke-direct {v0, v1, v2}, Lcom/android/settingslib/search/SearchIndexableData;-><init>(Ljava/lang/Class;Lcom/android/settingslib/search/Indexable$SearchIndexProvider;)V

    invoke-virtual {p0, v0}, Lio/mesalabs/unica/search/UnicaSearchIndexableResources;->addIndex(Lcom/android/settingslib/search/SearchIndexableData;)V

    return-void
.end method
