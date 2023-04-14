#include "PointLightComponent.h"
#include "GameObject.h"
#include "Game.h"
#include "DisplayWin32.h"

PointLightComponent::PointLightComponent(float constant, float linear, float quadratic)
{
	this->constant  = constant;
	this->linear    = linear;
	this->quadratic = quadratic;
}
