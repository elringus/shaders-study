using UnityEngine;
using System.Collections;

public class Rotator : MonoBehaviour
{
	private void Update () 
	{
		transform.Rotate(new Vector3(1, 1, 1), 100 * Time.deltaTime);
	}
}