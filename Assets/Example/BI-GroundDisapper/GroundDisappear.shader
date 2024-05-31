Shader "GroundDisapper"
{
	Properties
	{
		_Radius("Radius", Float) = 0
		_OutlineColor("OutlineColor", Color) = (0,0,0,0)
		_FadeRange("FadeRange", Float) = 0
		[Toggle(_DISAPPEAR_ON)]_Disappear("Disappear", Float) = 1
	}

	SubShader
	{
		Pass
		{
			Name "FORWARD"
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile _ _DISAPPEAR_ON
			#include "UnityCG.cginc"

			struct Input
			{
				float3 worldNormal;
				float3 worldPos;
			};

			int StartPosCount;
			float4 StartPosArr[5];
			float _Radius;
			float _FadeRange;
			float4 _OutlineColor;

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};

			v2f vert (appdata v)
			{
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
			
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 c = 0;

				//Lambert lighting
				fixed4 NdotL = dot(i.worldNormal, _WorldSpaceLightPos0.xyz);
				fixed4 diffuse = (NdotL * 0.5 + 0.5) * 0.4;

				#ifdef _DISAPPEAR_ON
					//获取渐变内侧终点
					float fadeMin = _Radius - _FadeRange;
					//获取渐变外侧起点，同时也是半径
					float fadeMax = _Radius;
					//起始假设该点在半径之外，倘若最后真的在半径之外，会被clip(0.999-1)剔除
					float outline = 1;
					//遍历所有的圆心，只要有一个小于1，最后就能被保留
					for (uint idx = 0; idx < StartPosCount; idx++)
					{
						float3 startPos = StartPosArr[idx].xyz;
						//saturate（该点离内侧的距离 / 外侧离内侧的距离）
						float fade = saturate((distance(i.worldPos, startPos) - fadeMin) / (fadeMax - fadeMin));
						outline *= fade;
					}
					clip(0.999 - outline);
					c = outline * _OutlineColor + diffuse;
				#else
					c = diffuse;
				#endif
			
				return c;
			}

			ENDCG
		}
	}
}