// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "GroundDisapper_ASE"
{
	Properties
	{
		_StartPos("StartPos", Vector) = (0,0,0,0)
		_StartPos1("StartPos1", Vector) = (0,0,0,0)
		_Radius("Radius", Float) = 0
		_OutlineColor("OutlineColor", Color) = (0,0,0,0)
		_FadeRange("FadeRange", Float) = 0
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGINCLUDE
		#include "UnityCG.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		struct Input
		{
			float3 worldNormal;
			float3 worldPos;
		};

		uniform float4 _OutlineColor;
		uniform float _Radius;
		uniform float _FadeRange;
		uniform float3 _StartPos;
		uniform float3 _StartPos1;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float3 ase_worldNormal = i.worldNormal;
			float3 ase_worldPos = i.worldPos;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float dotResult5_g1 = dot( ase_worldNormal , ase_worldlightDir );
			float feadRange40 = ( _Radius - _FadeRange );
			float radius39 = _Radius;
			float3 ase_vertex3Pos = mul( unity_WorldToObject, float4( i.worldPos , 1 ) );
			float smoothstepResult32 = smoothstep( feadRange40 , radius39 , distance( _StartPos , ase_vertex3Pos ));
			float smoothstepResult43 = smoothstep( feadRange40 , radius39 , distance( _StartPos1 , ase_vertex3Pos ));
			float temp_output_46_0 = ( smoothstepResult32 * smoothstepResult43 );
			clip( 0.99 - temp_output_46_0);
			o.Emission = ( ( (dotResult5_g1*0.5 + 0.5) * 0.4 ) + ( _OutlineColor * temp_output_46_0 ) ).rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float3 worldPos : TEXCOORD1;
				float3 worldNormal : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.worldNormal = worldNormal;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = IN.worldNormal;
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18935
2037;146;1221;577;1215.528;374.8193;2.181264;True;True
Node;AmplifyShaderEditor.RangedFloatNode;27;-713.3251,-980.1347;Inherit;False;Property;_Radius;Radius;2;0;Create;True;0;0;0;False;0;False;0;1.64;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;33;-731.243,-888.3133;Inherit;False;Property;_FadeRange;FadeRange;4;0;Create;True;0;0;0;False;0;False;0;0.61;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;34;-434.0788,-895.2519;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;39;-466.7644,-977.8251;Inherit;False;radius;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PosVertexDataNode;23;-659.7072,228.369;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;21;-633.7346,34.66108;Inherit;False;Property;_StartPos;StartPos;0;0;Create;True;0;0;0;False;0;False;0,0,0;-0.69,2.59,-3.61;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;40;-211.2963,-882.0425;Inherit;False;feadRange;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;36;-624.6571,492.9917;Inherit;False;Property;_StartPos1;StartPos1;1;0;Create;True;0;0;0;False;0;False;0,0,0;-2.03,0.99,-2.06;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.PosVertexDataNode;37;-652.6297,691.6997;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;44;-459.6355,686.8348;Inherit;False;40;feadRange;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;38;-432.0032,583.5485;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;45;-451.2205,770.7462;Inherit;False;39;radius;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;42;-452.4616,236.6679;Inherit;False;40;feadRange;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;24;-427.8383,123.5215;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;41;-451.0466,310.5793;Inherit;False;39;radius;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;43;-205.3508,645.8561;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;32;-176.1767,189.6892;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;46;62.25795,461.6512;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;29;46.42821,230.9611;Inherit;False;Property;_OutlineColor;OutlineColor;3;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,1,0.02782917,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.FunctionNode;28;37.62791,122.3425;Inherit;False;Half Lambert Term;-1;;1;86299dc21373a954aa5772333626c9c1;0;1;3;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;31;296.726,231.2334;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.4;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;293.5406,366.297;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;35;457.5022,307.7038;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClipNode;26;627.5424,377.6119;Inherit;False;3;0;COLOR;0,0,0,0;False;1;FLOAT;0.99;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;20;859.1669,336.1679;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;GroundDisapper_ASE;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;18;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;True;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;34;0;27;0
WireConnection;34;1;33;0
WireConnection;39;0;27;0
WireConnection;40;0;34;0
WireConnection;38;0;36;0
WireConnection;38;1;37;0
WireConnection;24;0;21;0
WireConnection;24;1;23;0
WireConnection;43;0;38;0
WireConnection;43;1;44;0
WireConnection;43;2;45;0
WireConnection;32;0;24;0
WireConnection;32;1;42;0
WireConnection;32;2;41;0
WireConnection;46;0;32;0
WireConnection;46;1;43;0
WireConnection;31;0;28;0
WireConnection;30;0;29;0
WireConnection;30;1;46;0
WireConnection;35;0;31;0
WireConnection;35;1;30;0
WireConnection;26;0;35;0
WireConnection;26;2;46;0
WireConnection;20;2;26;0
ASEEND*/
//CHKSM=B925C6B62B9A77873A6002EAAC357550B06AFD2F