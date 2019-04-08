using UnityEngine;

public class MoveCamera : MonoBehaviour
{
    public float speed = 1f;

    void Move(float x, float z)
    {
        Vector3 pos = Camera.main.transform.position;
        pos.x += x;
        pos.z += z;
        Camera.main.transform.position = pos;
    }

    void FixedUpdate()
    {
        if (Input.GetKeyDown(KeyCode.A) || Input.GetKeyDown(KeyCode.LeftArrow))
            Move(0, -speed);

        if (Input.GetKeyDown(KeyCode.D) || Input.GetKeyDown(KeyCode.RightArrow))
            Move(0, speed);

        if (Input.GetKeyDown(KeyCode.W) || Input.GetKeyDown(KeyCode.UpArrow))
            Move(speed, 0);

        if (Input.GetKeyDown(KeyCode.S) || Input.GetKeyDown(KeyCode.DownArrow))
            Move(-speed, 0);
    }
}
