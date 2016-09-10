/*
  Results for 10^6 elements
  - T_0: MFSet_NoPC_NoRK
  - T_1: MFSet_NoPC_RK
  - T_2: MFSet_PC_NoRK
  - T_3: MFSet_PC_RK
    - Faster when N <= E
  - T_4: MFSet_PC_NoRK_LL3u
  - T_5: MFSet_PC_NoRK_LL2u
  - T_6: MFSet_PC_NoRK_LL4u
    - Faster when N >> E

  Plot:
    log_2(T_i) en NxE = {1,2,4..2^n} x {1,2,4,..,2^e}
*/
// g++ -std=c++11 -fno-exceptions -fno-rtti -O3 mfset.cpp -o mfset
#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <vector>
#include <chrono>

#include "MFSet_NoPC_NoRK.h"
#include "MFSet_NoPC_RK.h"
#include "MFSet_PC_NoRK.h"
#include "MFSet_PC_RK.h"
#include "MFSet_PC_NoRK_LL3u.h"
#include "MFSet_PC_NoRK_LL2u.h"
#include "MFSet_PC_NoRK_LL4u.h"
#include "MFSet_PC_NoRK_LL4u_LE4u.h"

inline void Seed( uint32_t s )
{
    srand(s);
}

inline uint32_t Random( uint32_t min, uint32_t max )
{
    return min + rand()%(max-min);
}

template <typename MFST>
uint32_t Test( uint32_t num_nodes, uint32_t num_edges, bool b_verbose )
{
    // Init S = {0..N-1}
    MFST mfset( num_nodes );

    // Add E edges
    Seed( 666 );
    {
        auto start = std::chrono::system_clock::now();
        uint32_t num_added_edges;
        for( uint32_t it_e=0; it_e<num_edges; it_e++ )
        {
            uint32_t n1( Random(0,num_nodes) );
            uint32_t n2( Random(0,num_nodes) );
            if( n1 != n2 )
            {
                mfset.Merge( n1, n2 );
                num_added_edges++;
                if( b_verbose ) printf( "e(%d,%d)\n", n1, n2 );
            }
        }
        auto end = std::chrono::system_clock::now();
        std::chrono::duration<float> elapsed = end-start;
        printf( "Merged %d in %f sec\n", num_added_edges, elapsed.count() );
    }

    // Enumerate CC and return count
    return mfset.EnumerateCC(b_verbose);
}

int main( int argc, const char* argv[] )
{
    uint32_t num_nodes(10);
    uint32_t num_edges(5);
    bool bVerbose(true);
    int test_id(0);

    if( argc > 2 )
    {
        num_nodes = atoi(argv[1]);
        num_edges = atoi(argv[2]);
    }
    if( argc > 3 )
        bVerbose = (bool)atoi(argv[3]);
    if( argc > 4 )
        test_id = atoi(argv[4]);

    printf( "#N = %d, #E = %d\n", num_nodes, num_edges );

    uint32_t num_cc(0);
    switch( test_id )
    {
    case 0:
        printf( "Test0(): -PC, -RK, -LL----------------------------\n" );
        num_cc = Test<MFSet_NoPC_NoRK>( num_nodes, num_edges, bVerbose );
        break;
    case 1:
        printf( "Test1(): -PC, +RK, -LL----------------------------\n" );
        num_cc = Test<MFSet_NoPC_RK>( num_nodes, num_edges, bVerbose );
        break;
    case 2:
        printf( "Test2(): +PC, -RK, -LL----------------------------\n" );
        num_cc = Test<MFSet_PC_NoRK>( num_nodes, num_edges, bVerbose );
        break;
    case 3:
        printf( "Test3(): +PC, +RK, -LL----------------------------\n" );
        num_cc = Test<MFSet_PC_RK>( num_nodes, num_edges, bVerbose );
        break;
    case 4:
        printf( "Test4(): +PC, -RK, +LL3u--------------------------\n" );
        num_cc = Test<MFSet_PC_NoRK_LL3u>( num_nodes, num_edges, bVerbose );
        break;
    case 5:
        printf( "Test5(): +PC, -RK, +LL2u--------------------------\n" );
        num_cc = Test<MFSet_PC_NoRK_LL2u>( num_nodes, num_edges, bVerbose );
        break;
    case 6:
        printf( "Test6(): +PC, -RK, +LL4u--------------------------\n" );
        num_cc = Test<MFSet_PC_NoRK_LL4u>( num_nodes, num_edges, bVerbose );
        break;
    case 7:
        printf( "Test7(): +PC, -RK, +LL4u +LE4u--------------------\n" );
        num_cc = Test<MFSet_PC_NoRK_LL4u_LE4u>( num_nodes, num_edges, bVerbose );
        break;
    default:
        break;
    }

    return 0;
}
