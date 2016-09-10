#include <cstdio>
#include <cstdint>
#include <cstdlib>
#include <vector>
#include <chrono>
#include <cassert>

/* Same as MFSet_PC_NoRK_LL4u, but storing Edges explicitly on Merge.
   - Edges stored in an array<Edge>, identified by index
   - struct Edge stores (n1,n2,predE,succE), where pred/succ lists are disjoint per-CC
   - struct Node stores FirstE/LastE indices to edges

  \todo Try to SIMPLIFY Merge() code
*/
class MFSet_PC_NoRK_LL4u_LE4u
{
public:
    MFSet_PC_NoRK_LL4u_LE4u( uint32_t size ) { m_vecN.resize(size); Init(); }
    ~MFSet_PC_NoRK_LL4u_LE4u() {}
    inline void Init()
        {
            for( uint32_t it_n=0; it_n<m_vecN.size(); it_n++ )
            {
                m_vecN[it_n].m_FirstN = 0xFFFFFFFF; //Root, FirstN is empty
                m_vecN[it_n].m_LastN = 0xFFFFFFFF; //Root, ParentR is LastR, empty
                // root list
                m_vecN[it_n].m_PredR = it_n-1;
                m_vecN[it_n].m_SuccR = it_n+1;
            }
            m_vecN.front().m_PredR = m_vecN.size()-1;
            m_vecN.back().m_SuccR = 0;
        }
    inline uint32_t Find( uint32_t n )
        {
            if( m_vecN[n].m_ParentR < n ) // non-root, maybe empty
            {
                m_vecN[n].m_ParentR = Find( m_vecN[n].m_ParentR );
                return m_vecN[n].m_ParentR;
            }
            else //n < m_ParentR
                return n; //BECAUSE m_vecN[n].m_ParentR is LAST
        }

    /* FirstN-LastN lists
       r1;
         r1 -> r1.f -> r1.f.n ---> r1.l -> X
         |__________________________^
       r2;
         r2 -> r2.f -> r2.f.n ---> r2.l -> X
         |__________________________^
       r1 + r2:
         r1 -> r1.f -> r1.f.n -----> r1.l -> r2 -> r2.n -> .... -> r2.l -> X
         |_________________________________________________________^

       Merge( r1, r2 )
         r1.l.n = r2
         r1.l = r2.l
       For safety we should:
         r1.l.n = X
         r2.l = X
    */
    inline void Merge( uint32_t n1, uint32_t n2 )
        {
            // assert( n1 != n2 );
            uint32_t root1( Find(n1) );
            uint32_t root2( Find(n2) );

            //---- Merge nodes and list-nodes-in-CC

            // IMPORTANT: Using swap to avoid 2 large branches is
            // SLIGHTLY slower, but keeps code MUCH SHORTER, so we'll
            // do it by now

            // IMPORTANT: DO NOTHING IF ALREADY MERGED
            if( root1 == root2 )
            {
                //\todo EVEN IF they're already in the same CC, the
                //edge (n1,n2) MUST BE APPENDED to root1 list, which CANNOT BE EMPTY
                return;
            }
            else if( root2 < root1 ) std::swap(root1,root2);

            uint32_t last2( m_vecN[root2].m_LastN );
            m_vecN[root2].m_ParentR = root1;

            // Remove root2 from list of roots where root1 already is
            m_vecN[ m_vecN[root2].m_SuccR ].m_PredR = m_vecN[root2].m_PredR;
            m_vecN[ m_vecN[root2].m_PredR ].m_SuccR = m_vecN[root2].m_SuccR;

            // Add edge
            // Store edge \todo flag as MST, because it caused an actual Merge
            uint32_t eid = m_vecE.size(); //\todo If we support deletion, find First Empty edge here
            m_vecE.push_back( Edge() );
            Edge& edge = m_vecE.back();
            edge.m_Node1 = n1;
            edge.m_Node2 = n2;

            // Check emptiness
            bool bEmpty1( m_vecN[root1].m_FirstN == 0xFFFFFFFF );
            bool bEmpty2( m_vecN[root2].m_FirstN == 0xFFFFFFFF );
            if( !bEmpty1 && !bEmpty2 ) //none empty
            {
                // Merge nodes-in-cc
                m_vecN[ m_vecN[root1].m_LastN ].m_NextN = root2;
                m_vecN[root1].m_LastN = last2;
                // Merge edges-in-cc
                Node& child1( m_vecN[ m_vecN[root1].m_FirstN ] );
                Node& child2( m_vecN[ m_vecN[root2].m_FirstN ] );
                assert( child1.m_FirstE != 0xFFFFFFFF && child1.m_LastE != 0xFFFFFFFF );
                assert( child2.m_FirstE != 0xFFFFFFFF && child2.m_LastE != 0xFFFFFFFF );
                m_vecE[ child1.m_LastE ].m_SuccE = child2.m_FirstE;
                m_vecE[ child2.m_FirstE ].m_PredE = child1.m_LastE;
                // Append edge to child2.m_LastE
                m_vecE[ child2.m_LastE ].m_SuccE = eid;
                edge.m_PredE = child2.m_LastE;
                edge.m_SuccE = 0xFFFFFFFF;
                child1.m_LastE = eid;
                // TEMP: Unnecessary, done for safety
                child2.m_FirstE = 0xFFFFFFFF;
                child2.m_LastE = 0xFFFFFFFF;
            }
            else if( !bEmpty1 && bEmpty2 )
            {
                // Merge nodes-in-CC
                m_vecN[ m_vecN[root1].m_LastN ].m_NextN = root2;
                m_vecN[root1].m_LastN = root2;
                // Append edge to child1.m_LastE, ignore empty child2.m_LastE)
                Node& child1( m_vecN[ m_vecN[root1].m_FirstN ] );
                m_vecE[ child1.m_LastE ].m_SuccE = eid;
                edge.m_PredE = child1.m_LastE;
                edge.m_SuccE = 0xFFFFFFFF;
                child1.m_LastE = eid;
            }
            else if( bEmpty1 && !bEmpty2 )
            {
                // Merge nodes-in-CC
                m_vecN[ root1 ].m_FirstN = root2;
                m_vecN[ root1 ].m_LastN = last2;
                // Append edge to child1.m_LastE, ignore empty child2.m_LastE)
                Node& child2( m_vecN[ m_vecN[root2].m_FirstN ] );
                m_vecE[ child2.m_LastE ].m_SuccE = eid;
                edge.m_PredE = child2.m_LastE;
                edge.m_SuccE = 0xFFFFFFFF;
                child2.m_LastE = eid;
                // Transfrer edges-in-CC to root1 and append edge to child1.m_LastN
                Node& child1( m_vecN[ m_vecN[root1].m_FirstN ] );
                child1.m_FirstE = child2.m_FirstE;
                child1.m_LastE = child2.m_LastE;
                // TEMP: Unnecessary, done for safety
                child2.m_FirstE = 0xFFFFFFFF;
                child2.m_LastE = 0xFFFFFFFF;
            }
            else // both empty
            {
                // Merge nodes
                m_vecN[ root1 ].m_FirstN = root2;
                m_vecN[ root1 ].m_LastN = root2;
                // Append edge to child1, which is root2
                Node& child1( m_vecN[root2] );
                child1.m_FirstE = eid;
                child1.m_LastE = eid;
                edge.m_PredE = 0xFFFFFFFF;
                edge.m_SuccE = 0xFFFFFFFF;
            }
        }
    inline uint32_t EnumerateCC( bool b_verbose )
        {
            if( b_verbose )
            {
                // Count and enumerate {S_i} \in S
                std::vector< std::vector<uint32_t> > vec_cc;
                {
                    auto start = std::chrono::system_clock::now();
                    const uint32_t first_root(0);
                    //\todo NO NEED, 0 WILL ALWAYS BE A ROOT because
                    //there's no other num smaller!!
                    // while( first_root > m_vecN[first_root].m_ParentR ) first_root++;
                    uint32_t it_cc( first_root );
                    do
                    {
                        // create and fill CC
                        vec_cc.push_back( std::vector<uint32_t>() );
                        vec_cc.back().push_back( it_cc );
                        for( uint32_t it_ll=m_vecN[it_cc].m_FirstN;
                             it_ll != 0xFFFFFFFF;
                             it_ll = m_vecN[it_ll].m_NextN )
                            vec_cc.back().push_back( it_ll );
                        // next root
                        it_cc = m_vecN[it_cc].m_SuccR;
                    } while( it_cc != first_root );
                    auto end = std::chrono::system_clock::now();
                    std::chrono::duration<float> elapsed = end-start;
                    printf( "Enumerate CC = %d, in %f sec \n",
                            (int)vec_cc.size(), elapsed.count() );
                }
                // print
                for( uint32_t it_cc=0; it_cc<vec_cc.size(); it_cc++ )
                {
                    printf( "CC[%d] = %d [", it_cc, (int)vec_cc[it_cc].size() );
                    for( uint32_t it_nicc=0; it_nicc<vec_cc[it_cc].size(); it_nicc++ )
                        printf( " %d", vec_cc[it_cc][it_nicc] );
                    printf( " ]\n" );
                }
                // TEMP: Call EnumerateCC_Edges here to test both at once
                EnumerateCC_Edges(b_verbose);
                return vec_cc.size();
            }
            else
            {
                // Count and enumerate {S_i} \in S
                uint32_t num_cc(0);
                uint32_t sum(0); //\todo To avoid elimiation of code with no side-effects
                auto start = std::chrono::system_clock::now();
                const uint32_t first_root(0);
                //\todo NO NEED, 0 WILL ALWAYS BE A ROOT because
                //there's no other num smaller!!
                // while( first_root > m_vecN[first_root].m_ParentR ) first_root++;
                uint32_t it_cc( first_root );
                do
                {
                    // create and fill CC
                    for( uint32_t it_ll=m_vecN[it_cc].m_FirstN;
                         it_ll != 0xFFFFFFFF;
                         it_ll = m_vecN[it_ll].m_NextN )
                        sum += it_ll;
                    // next root
                    it_cc = m_vecN[it_cc].m_SuccR;
                    num_cc++;
                } while( it_cc != first_root );
                auto end = std::chrono::system_clock::now();
                std::chrono::duration<float> elapsed = end-start;
                printf( "Enumerate CC = %d, in %f sec \n",
                        num_cc, elapsed.count() );
                printf( "Sum =  %d\n", sum );
                return num_cc;
            }
        }
    inline uint32_t EnumerateCC_Edges( bool b_verbose )
        {
            // uint32_t num_cc = EnumerateCC(b_verbose);
            if( b_verbose )
            {
                // Count and enumerate {S_i} \in S
                std::vector< std::vector<uint32_t> > vec_cc;
                {
                    auto start = std::chrono::system_clock::now();
                    const uint32_t first_root(0);
                    //\todo NO NEED, 0 WILL ALWAYS BE A ROOT because
                    //there's no other num smaller!!
                    // while( first_root > m_vecN[first_root].m_ParentR ) first_root++;
                    uint32_t it_cc( first_root );
                    do
                    {
                        // create CC
                        vec_cc.push_back( std::vector<uint32_t>() );
                        if( m_vecN[it_cc].m_FirstN != 0xFFFFFFFF )
                        {
                            // Add CC edges
                            const Node& first_child( m_vecN[ m_vecN[it_cc].m_FirstN ] );
                            for( uint32_t it_e=first_child.m_FirstE;
                                 it_e != 0xFFFFFFFF;
                                 it_e = m_vecE[it_e].m_SuccE )
                                vec_cc.back().push_back( it_e );
                        }
                        // next root
                        it_cc = m_vecN[it_cc].m_SuccR;
                    } while( it_cc != first_root );
                    auto end = std::chrono::system_clock::now();
                    std::chrono::duration<float> elapsed = end-start;
                    printf( "Enumerate CC.Edges = %d, in %f sec \n",
                            (int)vec_cc.size(), elapsed.count() );
                }
                // print
                for( uint32_t it_cc=0; it_cc<vec_cc.size(); it_cc++ )
                {
                    printf( "CC.Edges[%d] = %d [", it_cc, (int)vec_cc[it_cc].size() );
                    for( uint32_t it_eicc=0; it_eicc<vec_cc[it_cc].size(); it_eicc++ )
                    {
                        uint32_t eid( vec_cc[it_cc][it_eicc] );
                        printf( " (%d,%d)", m_vecE[eid].m_Node1, m_vecE[eid].m_Node2 );
                    }
                    printf( " ]\n" );
                }
                return vec_cc.size();
            }
            else
                return 0;
            // else
            // {
            //     // Count and enumerate {S_i} \in S
            //     uint32_t num_cc(0);
            //     uint32_t sum(0); //\todo To avoid elimiation of code with no side-effects
            //     auto start = std::chrono::system_clock::now();
            //     const uint32_t first_root(0);
            //     //\todo NO NEED, 0 WILL ALWAYS BE A ROOT because
            //     //there's no other num smaller!!
            //     // while( first_root > m_vecN[first_root].m_ParentR ) first_root++;
            //     uint32_t it_cc( first_root );
            //     do
            //     {
            //         // create and fill CC
            //         for( uint32_t it_ll=m_vecN[it_cc].m_FirstN;
            //              it_ll != 0xFFFFFFFF;
            //              it_ll = m_vecN[it_ll].m_NextN )
            //             sum += it_ll;
            //         // next root
            //         it_cc = m_vecN[it_cc].m_SuccR;
            //         num_cc++;
            //     } while( it_cc != first_root );
            //     auto end = std::chrono::system_clock::now();
            //     std::chrono::duration<float> elapsed = end-start;
            //     printf( "Enumerate CC = %d, in %f sec \n",
            //             num_cc, elapsed.count() );
            //     printf( "Sum =  %d\n", sum );
            //     return num_cc;
            // }
            // return num_cc;
        }

private:
    struct Node
    {
        union { uint32_t m_LastN; uint32_t m_ParentR; }; //Last for for roots, Parent for children
        union { uint32_t m_FirstN; uint32_t m_NextN; }; //First for roots, Next for children
        union { uint32_t m_PredR; uint32_t m_FirstE; }; //R for roots, E for children
        union { uint32_t m_SuccR; uint32_t m_LastE; }; //R for roots, E for children
    };
    struct Edge
    {
        uint32_t m_Node1;
        uint32_t m_Node2;
        uint32_t m_SuccE;
        uint32_t m_PredE;
    };
    std::vector<Node> m_vecN;
    std::vector<Edge> m_vecE;
};
