#include common_scripts\_destructible;
#include destructible_scripts\toy_tv_flatscreen;
#using_animtree( "destructibles" );

main()
{
	toy_tvs_flatscreen_cinematic( "tv_video_monitor", ::RemoveTargetted );
}